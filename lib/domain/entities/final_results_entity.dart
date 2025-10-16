import 'package:equatable/equatable.dart';

class FinalResultsEntity extends Equatable {
  final DateTime timestamp;
  final DeviceInfoEntity deviceInfo;
  final NetworkInfoEntity networkInfo;
  final SpeedTestResultEntity speedTestResult;
  final PingResultEntity pingResult;

  const FinalResultsEntity({
    required this.timestamp,
    required this.deviceInfo,
    required this.networkInfo,
    required this.speedTestResult,
    required this.pingResult,
  });

  @override
  List<Object> get props => [
        timestamp,
        deviceInfo,
        networkInfo,
        speedTestResult,
        pingResult,
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

/// Network information entity
class NetworkInfoEntity extends Equatable {
  final String connectionType;
  final String? wifiName;
  final String? wifiFrequency;
  final int? wifiSignalStrength; // RSSI
  final int? wifiLinkSpeed;
  final String? wifiBSSID;
  final String? externalIP;
  final String? internalIP;

  const NetworkInfoEntity({
    required this.connectionType,
    this.wifiName,
    this.wifiFrequency,
    this.wifiSignalStrength,
    this.wifiLinkSpeed,
    this.wifiBSSID,
    this.externalIP,
    this.internalIP,
  });

  @override
  List<Object?> get props => [
        connectionType,
        wifiName,
        wifiFrequency,
        wifiSignalStrength,
        wifiLinkSpeed,
        wifiBSSID,
        externalIP,
        internalIP,
      ];
}

/// Speed test result entity
class SpeedTestResultEntity extends Equatable {
  final double downloadSpeed; // Mbps
  final double uploadSpeed; // Mbps
  final double ping; // ms
  final double jitter; // ms
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

class PingResultEntity extends Equatable {
  final double averageLatencyMs;
  final double minLatencyMs;
  final double maxLatencyMs;
  final double jitterMs;
  final double packetLossPercentage;
  final int transmitted;
  final int received;
  final List<double> samplesMs;

  const PingResultEntity({
    required this.averageLatencyMs,
    required this.minLatencyMs,
    required this.maxLatencyMs,
    required this.jitterMs,
    required this.packetLossPercentage,
    required this.transmitted,
    required this.received,
    this.samplesMs = const [],
  });

  double get successRate => transmitted == 0 ? 0 : received / transmitted;

  @override
  List<Object?> get props => [
        averageLatencyMs,
        minLatencyMs,
        maxLatencyMs,
        jitterMs,
        packetLossPercentage,
        transmitted,
        received,
        samplesMs,
      ];
}
