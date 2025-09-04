import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

abstract class PlatformNetworkService {
  Future<String?> getWifiName();
  Future<String?> getWifiIP();
  Future<int?> getWifiSpeed();
}

class PlatformNetworkServiceImpl implements PlatformNetworkService {
  final NetworkInfo _networkInfo = NetworkInfo();

  @override
  Future<String?> getWifiName() async {
    if (Platform.isWindows) {
      return "MockWiFi-Development";
    }
    return await _networkInfo.getWifiName();
  }

  @override
  Future<String?> getWifiIP() async {
    if (Platform.isWindows) {
      return "192.168.1.100"; // Mock
    }
    return await _networkInfo.getWifiIP();
  }

  @override
  Future<int?> getWifiSpeed() async {
    if (Platform.isWindows) {
      return 100; 
    }

    return await _performSpeedTest();
  }

  Future<int?> _performSpeedTest() async {

    return null;
  }
}
