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
    // Para plataforma web, retorna dados mock
    if (kIsWeb) {
      return const NetworkInfoEntity(
        connectionType: 'WiFi',
        wifiName: 'MAX-5G-Demo',
        wifiSignalStrength: -45, // Sinal excelente para permitir teste
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

    final scanResults = await _scanWifi();

    int? rssi;
    String? frequencyLabel;
    int? linkSpeed;
    if (ssid != null && scanResults.isNotEmpty) {
      final match = scanResults.firstWhere(
        (e) => _sanitizeSsid(e.ssid) == ssid.trim(),
        orElse: () => scanResults.first,
      );
      rssi = match.level; // dBm
      final freq = match.frequency; // MHz
      if (freq != null) {
        frequencyLabel = freq >= 5000 ? '5 GHz' : '2.4 GHz';
      }
      linkSpeed = await _getLinkSpeed();
    }

    final bssid = await _safeGet(() => networkInfo.getWifiBSSID());
    final internalIP = await _safeGet(() => networkInfo.getWifiIP());

    return NetworkInfoEntity(
      connectionType: 'WiFi',
      wifiName: ssid,
      wifiSignalStrength: rssi,
      wifiFrequency: frequencyLabel,
      wifiLinkSpeed: linkSpeed,
      wifiBSSID: bssid,
      internalIP: internalIP,
    );
  }

  @override
  Future<NetworkInfoEntity> getNetworkInfo() async {
    return getInitialNetworkInfo();
  }

  Future<bool> _ensureLocationPermission() async {
    // Na web, não há permissões de localização para WiFi
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
    // Na web, retorna lista mock
    if (kIsWeb) {
      return [
        _WifiEntry(
          ssid: 'MAX-5G-Demo',
          bssid: '00:11:22:33:44:55',
          level: -45, // Sinal excelente
          frequency: 5180, // 5 GHz
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
      await wscan.WiFiScan.instance.startScan();
      final list = await wscan.WiFiScan.instance.getScannedResults();
      return list
          .map((e) => _WifiEntry(
                ssid: e.ssid,
                bssid: e.bssid,
                level: e.level,
                frequency: e.frequency,
              ))
          .toList();
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
    // Na web, retorna velocidade mock
    if (kIsWeb) return 150; // 150 Mbps
    
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
  final int? level; // dBm
  final int? frequency; // MHz

  _WifiEntry({this.ssid, this.bssid, this.level, this.frequency});
}
