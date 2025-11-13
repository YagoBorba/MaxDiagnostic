import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart' as nip;
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart' as wscan;

import '../../core/error/exceptions.dart';
import '../../domain/entities/final_results_entity.dart';

abstract class NetworkInfoLocalDataSource {
  Future<NetworkInfoEntity> getInitialNetworkInfo();

  Future<NetworkInfoEntity> getNetworkInfo();
}

class NetworkInfoLocalDataSourceImpl implements NetworkInfoLocalDataSource {
  final nip.NetworkInfo networkInfo;
  final Connectivity connectivity;
  static const MethodChannel _wifiChannel =
      MethodChannel('maxt_diagnostic/wifi');

  NetworkInfoLocalDataSourceImpl({
    required this.networkInfo,
    required this.connectivity,
  });

  @override
  Future<NetworkInfoEntity> getInitialNetworkInfo() async {
    if (kIsWeb) {
      return const NetworkInfoEntity(
        connectionType: 'WiFi',
        wifiName: 'MAX-5G-Demo',
        wifiSignalStrength: -45,
        wifiFrequency: '5 GHz',
        wifiLinkSpeed: 150,
        wifiBSSID: '00:11:22:33:44:55',
        internalIP: '192.168.1.100',
        externalIP: '203.0.113.1',
        isp: 'Simulated ISP',
      );
    }

    final granted = await _ensureLocationPermission();
    if (!granted) {
      throw const PermissionException('Location permission not granted');
    }

    return _collectNetworkSnapshot();
  }

  @override
  Future<NetworkInfoEntity> getNetworkInfo() async {
    return _collectNetworkSnapshot();
  }

  Future<NetworkInfoEntity> _collectNetworkSnapshot() async {
    final publicInfo = await _getPublicIpDetails();

    final conn = await connectivity.checkConnectivity();
    if (!conn.contains(ConnectivityResult.wifi)) {
      return NetworkInfoEntity(
        connectionType: 'none',
        externalIP: publicInfo.externalIP,
        isp: publicInfo.isp,
      );
    }

    final rawSsid = await _safeGet(() => networkInfo.getWifiName());
    final ssid = _sanitizeSsid(rawSsid);
    final bssid = await _safeGet(() => networkInfo.getWifiBSSID());
    final internalIP = await _safeGet(() => networkInfo.getWifiIP());

    final scanResults = await _scanWifi();

    int? rssi;
    String? frequencyLabel;
    int? linkSpeed;
    int? channel;
    String? standard;

    final _WifiEntry? match = _findBestWifiMatch(
      targetSsid: ssid,
      targetBssid: bssid,
      scanResults: scanResults,
    );

    if (match != null) {
      rssi = match.level;
      final freq = match.frequency;
      if (freq != null) {
        frequencyLabel = freq >= 5000 ? '5 GHz' : '2.4 GHz';
      }
      linkSpeed = await _getLinkSpeed();
      channel = match.channel ?? _freqToChannel(freq);
      standard = match.standard;
    }

    return NetworkInfoEntity(
      connectionType: 'WiFi',
      wifiName: ssid,
      wifiSignalStrength: rssi,
      wifiFrequency: frequencyLabel,
      wifiLinkSpeed: linkSpeed,
      wifiBSSID: bssid,
      internalIP: internalIP,
      externalIP: publicInfo.externalIP,
      isp: publicInfo.isp,
      wifiChannel: channel,
      wifiStandard: standard,
    );
  }

  _WifiEntry? _findBestWifiMatch({
    required String? targetSsid,
    required String? targetBssid,
    required List<_WifiEntry> scanResults,
  }) {
    if (scanResults.isEmpty) {
      return null;
    }

    if (targetBssid != null) {
      final byBssid = scanResults.firstWhere(
        (entry) => entry.bssid == targetBssid,
        orElse: () => _WifiEntry.empty(),
      );
      if (byBssid.bssid != null) {
        return byBssid;
      }
    }

    if (targetSsid != null) {
      final bySsid = scanResults.firstWhere(
        (entry) => _sanitizeSsid(entry.ssid) == targetSsid.trim(),
        orElse: () => _WifiEntry.empty(),
      );
      if (bySsid.bssid != null || bySsid.ssid != null) {
        return bySsid;
      }
    }

    return scanResults.first;
  }

  Future<({String? externalIP, String? isp})> _getPublicIpDetails() async {
    if (kIsWeb) {
      return (externalIP: '203.0.113.1', isp: 'Simulated ISP');
    }

    try {
      final uri = Uri.parse('http://ip-api.com/json/?fields=query,isp');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final ip = data['query'] as String?;
        final isp = data['isp'] as String?;
        return (externalIP: ip, isp: isp);
      }
      return (externalIP: null, isp: null);
    } catch (_) {
      return (externalIP: null, isp: null);
    }
  }

  Future<bool> _ensureLocationPermission() async {
    if (kIsWeb) {
      return true;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.locationWhenInUse.status;
      if (status.isGranted) {
        return true;
      }
      final requested = await Permission.locationWhenInUse.request();
      return requested.isGranted;
    }
    return true;
  }

  Future<List<_WifiEntry>> _scanWifi() async {
    if (kIsWeb) {
      return [
        _WifiEntry(
          ssid: 'MAX-5G-Demo',
          bssid: '00:11:22:33:44:55',
          level: -45,
          frequency: 5180,
          channel: _freqToChannel(5180),
          standard: '802.11ac (WiFi 5)',
        ),
      ];
    }

    try {
      final canStart =
          await wscan.WiFiScan.instance.canStartScan(askPermissions: false);
      if (canStart != wscan.CanStartScan.yes) {
        if (canStart == wscan.CanStartScan.notSupported) {
          throw const NetworkException('WiFi scan not supported');
        }
        await _ensureLocationPermission();
      }

      try {
        await wscan.WiFiScan.instance.startScan();
      } catch (_) {
        // ignore: avoid_catches_without_on_clauses
      }

      final list = await wscan.WiFiScan.instance.getScannedResults();
      return list.map((entry) {
        String? standardLabel;
        int? channel;
        int? channelWidthIdx;

        try {
          final dynamic ap = entry;
          final dynamic std = ap.standard;
          if (std != null) {
            final label = std.toString();
            if (label.contains('legacy')) {
              standardLabel = '802.11a/b/g';
            } else if (label.endsWith('.n')) {
              standardLabel = '802.11n';
            } else if (label.endsWith('.ac')) {
              standardLabel = '802.11ac (WiFi 5)';
            } else if (label.endsWith('.ax')) {
              standardLabel = '802.11ax (WiFi 6)';
            }
          }

          final dynamic ch = ap.channel;
          if (ch is int) {
            channel = ch;
          }

          final dynamic cw = ap.channelWidth;
          if (cw is Enum) {
            channelWidthIdx = cw.index;
          }
        } catch (_) {
          // ignore reflection failures
        }

        channel ??= _freqToChannel(entry.frequency);

        return _WifiEntry(
          ssid: entry.ssid,
          bssid: entry.bssid,
          level: entry.level,
          frequency: entry.frequency,
          channelWidth: channelWidthIdx,
          standard: standardLabel,
          channel: channel,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<T?> _safeGet<T>(Future<T?> Function() action) async {
    try {
      return await action();
    } catch (_) {
      return null;
    }
  }

  Future<int?> _getLinkSpeed() async {
    if (kIsWeb) {
      return 150;
    }

    if (!Platform.isAndroid) {
      return null;
    }

    try {
      final speed = await _wifiChannel.invokeMethod<int>('getLinkSpeed');
      return speed;
    } catch (_) {
      return null;
    }
  }

  String? _sanitizeSsid(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.length >= 2 &&
        trimmed.startsWith('"') &&
        trimmed.endsWith('"')) {
      return trimmed.substring(1, trimmed.length - 1);
    }
    return trimmed;
  }
}

class _WifiEntry {
  final String? ssid;
  final String? bssid;
  final int? level;
  final int? frequency;
  final int? channelWidth;
  final String? standard;
  final int? channel;

  const _WifiEntry({
    this.ssid,
    this.bssid,
    this.level,
    this.frequency,
    this.channelWidth,
    this.standard,
    this.channel,
  });

  factory _WifiEntry.empty() => const _WifiEntry();
}

int? _freqToChannel(int? freq) {
  if (freq == null) {
    return null;
  }
  if (freq >= 2412 && freq <= 2484) {
    if (freq == 2484) {
      return 14;
    }
    final ch = ((freq - 2412) / 5).round() + 1;
    if (ch >= 1 && ch <= 13) {
      return ch;
    }
  }
  if (freq >= 5005 && freq <= 5895) {
    final ch = ((freq - 5000) / 5).round();
    if (ch > 0) {
      return ch;
    }
  }
  if (freq >= 5955 && freq <= 7115) {
    final ch = ((freq - 5955) / 5).round() + 1;
    if (ch > 0) {
      return ch;
    }
  }
  return null;
}
