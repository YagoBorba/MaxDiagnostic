import 'package:equatable/equatable.dart';

class FinalResultsEntity extends Equatable {
  final DateTime timestamp;
  final DeviceInfoEntity deviceInfo;
  final NetworkInfoEntity networkInfo;
  final NetworkInfoEntity initialNetworkInfo;
  final SpeedTestResultEntity speedTestResult;

  const FinalResultsEntity({
    required this.timestamp,
    required this.deviceInfo,
    required this.networkInfo,
    required this.initialNetworkInfo,
    required this.speedTestResult,
  });

  @override
  List<Object> get props => [
        timestamp,
        deviceInfo,
        networkInfo,
        initialNetworkInfo,
        speedTestResult,
      ];
}

class DeviceInfoEntity extends Equatable {
  final String deviceModel;
  final String deviceBrand;
  final String operatingSystem;
  final String osVersion;
  final String? deviceId;

  const DeviceInfoEntity({
    required this.deviceModel,
    required this.deviceBrand,
    required this.operatingSystem,
    required this.osVersion,
    this.deviceId,
  });

  @override
  List<Object?> get props => [
        deviceModel,
        deviceBrand,
        operatingSystem,
        osVersion,
        deviceId,
      ];
}

class NetworkInfoEntity extends Equatable {
  final String connectionType;
  final String? wifiName;
  final String? wifiFrequency;
  final int? wifiSignalStrength;
  final int? wifiLinkSpeed;
  final String? wifiBSSID;
  final String? internalIP;
  final String? externalIP;
  final String? isp;
  final int? wifiChannel;
  final String? wifiStandard;

  const NetworkInfoEntity({
    required this.connectionType,
    this.wifiName,
    this.wifiFrequency,
    this.wifiSignalStrength,
    this.wifiLinkSpeed,
    this.wifiBSSID,
    this.internalIP,
    this.externalIP,
    this.isp,
    this.wifiChannel,
    this.wifiStandard,
  });

  @override
  List<Object?> get props => [
        connectionType,
        wifiName,
        wifiFrequency,
        wifiSignalStrength,
        wifiLinkSpeed,
        wifiBSSID,
        internalIP,
        externalIP,
        isp,
        wifiChannel,
        wifiStandard,
      ];
}

class SpeedTestResultEntity extends Equatable {
  final double downloadSpeed;
  final double uploadSpeed;
  final double ping;
  final double jitter;
  final String serverLocation;
  final DateTime testStartTime;
  final DateTime testEndTime;
  final bool testCompleted;
  final String? errorMessage;

  const SpeedTestResultEntity({
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.ping,
    required this.jitter,
    required this.serverLocation,
    required this.testStartTime,
    required this.testEndTime,
    required this.testCompleted,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        downloadSpeed,
        uploadSpeed,
        ping,
        jitter,
        serverLocation,
        testStartTime,
        testEndTime,
        testCompleted,
        errorMessage,
      ];
}
