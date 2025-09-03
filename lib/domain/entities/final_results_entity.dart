import 'package:equatable/equatable.dart';

/// Entity representing the final diagnostic results
/// This is the core business object containing all diagnostic information
class FinalResultsEntity extends Equatable {
  final DateTime timestamp;
  final DeviceInfoEntity deviceInfo;
  final NetworkInfoEntity networkInfo;
  final SpeedTestResultEntity speedTestResult;

  const FinalResultsEntity({
    required this.timestamp,
    required this.deviceInfo,
    required this.networkInfo,
    required this.speedTestResult,
  });

  @override
  List<Object> get props => [
        timestamp,
        deviceInfo,
        networkInfo,
        speedTestResult,
      ];
}

/// Device information entity
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

/// Entity representing the progress of diagnostic test
class DiagnosticProgressEntity extends Equatable {
  final DiagnosticStage stage;
  final double progress; // 0.0 to 1.0
  final String message;
  final DateTime timestamp;

  const DiagnosticProgressEntity({
    required this.stage,
    required this.progress,
    required this.message,
    required this.timestamp,
  });

  @override
  List<Object> get props => [stage, progress, message, timestamp];
}

/// Diagnostic stages enum
enum DiagnosticStage {
  initializing,
  collectingDeviceInfo,
  collectingNetworkInfo,
  startingSpeedTest,
  runningDownloadTest,
  runningUploadTest,
  runningLatencyTest,
  runningJitterTest,
  collectingAdditionalInfo,
  completed,
  error,
}

extension DiagnosticStageExtension on DiagnosticStage {
  String get displayName {
    switch (this) {
      case DiagnosticStage.initializing:
        return 'Inicializando...';
      case DiagnosticStage.collectingDeviceInfo:
        return 'Coletando informações do dispositivo...';
      case DiagnosticStage.collectingNetworkInfo:
        return 'Coletando informações de rede...';
      case DiagnosticStage.startingSpeedTest:
        return 'Iniciando teste de velocidade...';
      case DiagnosticStage.runningDownloadTest:
        return 'Testando velocidade de download...';
      case DiagnosticStage.runningUploadTest:
        return 'Testando velocidade de upload...';
      case DiagnosticStage.runningLatencyTest:
        return 'Testando latência...';
      case DiagnosticStage.runningJitterTest:
        return 'Testando jitter...';
      case DiagnosticStage.collectingAdditionalInfo:
        return 'Coletando informações adicionais...';
      case DiagnosticStage.completed:
        return 'Teste concluído!';
      case DiagnosticStage.error:
        return 'Erro durante o teste';
    }
  }
}
