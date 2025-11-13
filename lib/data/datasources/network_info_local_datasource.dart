import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart' as nip;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart' as wscan;
import 'package:flutter/foundation.dart';

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
      );
    }

    final granted = await _ensureLocationPermission();
    if (!granted) {
      throw const PermissionException('Location permission not granted');
    }

    final conn = await connectivity.checkConnectivity();
    if (!conn.contains(ConnectivityResult.wifi)) {
      return const NetworkInfoEntity(connectionType: 'none');
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
    _WifiEntry? match;

    if (bssid != null && scanResults.isNotEmpty) {
      match = scanResults.firstWhere(
        (e) => e.bssid == bssid,
        orElse: () => _WifiEntry(ssid: null, bssid: null, level: null, frequency: null), 
      );
    }
    
    if (match?.bssid == null && ssid != null && scanResults.isNotEmpty) {
       match = scanResults.firstWhere(
        (e) => _sanitizeSsid(e.ssid) == ssid.trim(),
        orElse: () => scanResults.first,
      );
    } else if (match?.bssid == null && scanResults.isNotEmpty) {
      match = scanResults.first;
    }


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
      wifiChannel: channel,
      wifiStandard: standard,
    );
  }

  @override
  Future<NetworkInfoEntity> getNetworkInfo() async {
    return getInitialNetworkInfo();
  }

  Future<bool> _ensureLocationPermission() async {
    if (kIsWeb) return true;
    
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.locationWhenInUse.status;
      if (status.isGranted) return true;
      final req = await Permission.locationWhenInUse.request();
      return req.isGranted;
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
      final can =
          await wscan.WiFiScan.instance.canStartScan(askPermissions: false);
      if (can != wscan.CanStartScan.yes) {
        if (can == wscan.CanStartScan.notSupported) {
          throw const NetworkException('WiFi scan not supported');
        }
        await _ensureLocationPermission();
      }
      
      try {
        await wscan.WiFiScan.instance.startScan();
      } catch (_) {
      }
      
      final list = await wscan.WiFiScan.instance.getScannedResults();
      return list.map((e) {
        String? standardLabel;
        int? channel;
        int? channelWidthIdx;
        try {
          final dynamic ap = e;
          final dynamic std = ap.standard; 
          if (std != null) {
            final String s = std.toString();
            if (s.contains('legacy')) standardLabel = '802.11a/b/g';
            else if (s.endsWith('.n')) standardLabel = '802.11n';
            else if (s.endsWith('.ac')) standardLabel = '802.11ac (WiFi 5)';
            else if (s.endsWith('.ax')) standardLabel = '802.11ax (WiFi 6)';
          }
          final dynamic ch = ap.channel; 
          if (ch is int) channel = ch;
          final dynamic cw = ap.channelWidth;
          if (cw != null && cw is Enum) {
            channelWidthIdx = cw.index as int;
          }
        } catch (_) {}

        channel ??= _freqToChannel(e.frequency);

        return _WifiEntry(
          ssid: e.ssid,
          bssid: e.bssid,
          level: e.level,
          frequency: e.frequency,
          channelWidth: channelWidthIdx,
          standard: standardLabel,
          channel: channel,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<T?> _safeGet<T>(Future<T?> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }

  Future<int?> _getLinkSpeed() async {
    if (kIsWeb) return 150; 
    
    if (!Platform.isAndroid) return null;
    try {
      final speed = await _wifiChannel.invokeMethod<int>('getLinkSpeed');
      return speed;
    } catch (_) {
      return null;
    }
  }

  String? _sanitizeSsid(String? value) {
    if (value == null) return null;
    final t = value.trim();
    if (t.length >= 2 && t.startsWith('"') && t.endsWith('"')) {
      return t.substring(1, t.length - 1);
    }
    return t;
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

  _WifiEntry({this.ssid, this.bssid, this.level, this.frequency, this.channelWidth, this.standard, this.channel});
}

int? _freqToChannel(int? freq) {
  if (freq == null) return null;
  if (freq >= 2412 && freq <= 2484) {
    if (freq == 2484) return 14;
    final ch = ((freq - 2412) / 5).round() + 1;
    if (ch >= 1 && ch <= 13) return ch;
  }
  if (freq >= 5005 && freq <= 5895) {
    final ch = ((freq - 5000) / 5).round();
    if (ch > 0) return ch;
  }
  if (freq >= 5955 && freq <= 7115) {
    final ch = ((freq - 5955) / 5).round() + 1;
    if (ch > 0) return ch;
  }
  return null;
}
