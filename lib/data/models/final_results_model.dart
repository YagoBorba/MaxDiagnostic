import '../../domain/entities/final_results_entity.dart';

/// Data model for FinalResultsEntity
/// Handles JSON serialization/deserialization
class FinalResultsModel extends FinalResultsEntity {
  const FinalResultsModel({
    required super.timestamp,
    required super.deviceInfo,
    required super.networkInfo,
    required super.speedTestResult,
  });

  factory FinalResultsModel.fromJson(Map<String, dynamic> json) {
    return FinalResultsModel(
      timestamp: DateTime.parse(json['timestamp']),
      deviceInfo: DeviceInfoModel.fromJson(json['deviceInfo']),
      networkInfo: NetworkInfoModel.fromJson(json['networkInfo']),
      speedTestResult: SpeedTestResultModel.fromJson(json['speedTestResult']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'deviceInfo': (deviceInfo as DeviceInfoModel).toJson(),
      'networkInfo': (networkInfo as NetworkInfoModel).toJson(),
      'speedTestResult': (speedTestResult as SpeedTestResultModel).toJson(),
    };
  }

  factory FinalResultsModel.fromEntity(FinalResultsEntity entity) {
    return FinalResultsModel(
      timestamp: entity.timestamp,
      deviceInfo: entity.deviceInfo,
      networkInfo: entity.networkInfo,
      speedTestResult: entity.speedTestResult,
    );
  }
}

/// Data model for DeviceInfoEntity
class DeviceInfoModel extends DeviceInfoEntity {
  const DeviceInfoModel({
    required super.deviceModel,
    required super.deviceBrand,
    required super.operatingSystem,
    required super.osVersion,
    super.deviceId,
  });

  factory DeviceInfoModel.fromJson(Map<String, dynamic> json) {
    return DeviceInfoModel(
      deviceModel: json['deviceModel'],
      deviceBrand: json['deviceBrand'],
      operatingSystem: json['operatingSystem'],
      osVersion: json['osVersion'],
      deviceId: json['deviceId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceModel': deviceModel,
      'deviceBrand': deviceBrand,
      'operatingSystem': operatingSystem,
      'osVersion': osVersion,
      'deviceId': deviceId,
    };
  }
}

/// Data model for NetworkInfoEntity
class NetworkInfoModel extends NetworkInfoEntity {
  const NetworkInfoModel({
    required super.connectionType,
    super.wifiName,
    super.wifiFrequency,
    super.wifiSignalStrength,
    super.wifiLinkSpeed,
    super.wifiBSSID,
    super.externalIP,
    super.internalIP,
  });

  factory NetworkInfoModel.fromJson(Map<String, dynamic> json) {
    return NetworkInfoModel(
      connectionType: json['connectionType'],
      wifiName: json['wifiName'],
      wifiFrequency: json['wifiFrequency'],
      wifiSignalStrength: json['wifiSignalStrength'],
      wifiLinkSpeed: json['wifiLinkSpeed'],
      wifiBSSID: json['wifiBSSID'],
      externalIP: json['externalIP'],
      internalIP: json['internalIP'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connectionType': connectionType,
      'wifiName': wifiName,
      'wifiFrequency': wifiFrequency,
      'wifiSignalStrength': wifiSignalStrength,
      'wifiLinkSpeed': wifiLinkSpeed,
      'wifiBSSID': wifiBSSID,
      'externalIP': externalIP,
      'internalIP': internalIP,
    };
  }
}

/// Data model for SpeedTestResultEntity
class SpeedTestResultModel extends SpeedTestResultEntity {
  const SpeedTestResultModel({
    required super.downloadSpeed,
    required super.uploadSpeed,
    required super.ping,
    required super.jitter,
    required super.serverLocation,
    required super.testStartTime,
    required super.testEndTime,
    required super.testCompleted,
    super.errorMessage,
  });

  factory SpeedTestResultModel.fromJson(Map<String, dynamic> json) {
    return SpeedTestResultModel(
      downloadSpeed: json['downloadSpeed']?.toDouble() ?? 0.0,
      uploadSpeed: json['uploadSpeed']?.toDouble() ?? 0.0,
      ping: json['ping']?.toDouble() ?? 0.0,
      jitter: json['jitter']?.toDouble() ?? 0.0,
      serverLocation: json['serverLocation'] ?? '',
      testStartTime: DateTime.parse(json['testStartTime']),
      testEndTime: DateTime.parse(json['testEndTime']),
      testCompleted: json['testCompleted'] ?? false,
      errorMessage: json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'downloadSpeed': downloadSpeed,
      'uploadSpeed': uploadSpeed,
      'ping': ping,
      'jitter': jitter,
      'serverLocation': serverLocation,
      'testStartTime': testStartTime.toIso8601String(),
      'testEndTime': testEndTime.toIso8601String(),
      'testCompleted': testCompleted,
      'errorMessage': errorMessage,
    };
  }
}

/// Data model for DiagnosticProgressEntity
class DiagnosticProgressModel extends DiagnosticProgressEntity {
  const DiagnosticProgressModel({
    required super.stage,
    required super.progress,
    required super.message,
    required super.timestamp,
  });

  factory DiagnosticProgressModel.fromJson(Map<String, dynamic> json) {
    return DiagnosticProgressModel(
      stage: DiagnosticStage.values.firstWhere(
        (e) => e.toString() == json['stage'],
        orElse: () => DiagnosticStage.initializing,
      ),
      progress: json['progress']?.toDouble() ?? 0.0,
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage': stage.toString(),
      'progress': progress,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
