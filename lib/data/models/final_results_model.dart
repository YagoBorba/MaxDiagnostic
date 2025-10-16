import '../../domain/entities/final_results_entity.dart';
import 'ping_result_model.dart';

class FinalResultsModel extends FinalResultsEntity {
  const FinalResultsModel({
    required super.timestamp,
    required DeviceInfoModel super.deviceInfo,
    required NetworkInfoModel super.networkInfo,
    required SpeedTestResultModel super.speedTestResult,
    required PingResultModel super.pingResult,
  });

  factory FinalResultsModel.fromJson(Map<String, dynamic> json) {
    return FinalResultsModel(
      timestamp: DateTime.parse(json['timestamp']),
      deviceInfo: DeviceInfoModel.fromJson(json['deviceInfo']),
      networkInfo: NetworkInfoModel.fromJson(json['networkInfo']),
      speedTestResult: SpeedTestResultModel.fromJson(json['speedTestResult']),
      pingResult: json['pingResult'] != null
          ? PingResultModel.fromJson(json['pingResult'])
          : const PingResultModel.empty(),
    );
  }

  factory FinalResultsModel.fromEntity(FinalResultsEntity entity) {
    return FinalResultsModel(
      timestamp: entity.timestamp,
      deviceInfo: DeviceInfoModel.fromEntity(entity.deviceInfo),
      networkInfo: NetworkInfoModel.fromEntity(entity.networkInfo),
      speedTestResult: SpeedTestResultModel.fromEntity(entity.speedTestResult),
      pingResult: PingResultModel.fromEntity(entity.pingResult),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'deviceInfo': (deviceInfo as DeviceInfoModel).toJson(),
      'networkInfo': (networkInfo as NetworkInfoModel).toJson(),
      'speedTestResult': (speedTestResult as SpeedTestResultModel).toJson(),
      'pingResult': (pingResult as PingResultModel).toJson(),
    };
  }
}

class DeviceInfoModel extends DeviceInfoEntity {
  const DeviceInfoModel({
    required super.deviceModel,
    required super.deviceBrand,
    required super.operatingSystem,
    required super.osVersion,
    super.deviceId,
  });

  factory DeviceInfoModel.fromEntity(DeviceInfoEntity entity) {
    return DeviceInfoModel(
      deviceModel: entity.deviceModel,
      deviceBrand: entity.deviceBrand,
      operatingSystem: entity.operatingSystem,
      osVersion: entity.osVersion,
      deviceId: entity.deviceId,
    );
  }

  factory DeviceInfoModel.fromJson(Map<String, dynamic> json) {
    return DeviceInfoModel(
      deviceModel: json['deviceModel'] as String,
      deviceBrand: json['deviceBrand'] as String,
      operatingSystem: json['operatingSystem'] as String,
      osVersion: json['osVersion'] as String,
      deviceId: json['deviceId'] as String?,
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

  factory NetworkInfoModel.fromEntity(NetworkInfoEntity entity) {
    return NetworkInfoModel(
      connectionType: entity.connectionType,
      wifiName: entity.wifiName,
      wifiFrequency: entity.wifiFrequency,
      wifiSignalStrength: entity.wifiSignalStrength,
      wifiLinkSpeed: entity.wifiLinkSpeed,
      wifiBSSID: entity.wifiBSSID,
      externalIP: entity.externalIP,
      internalIP: entity.internalIP,
    );
  }

  factory NetworkInfoModel.fromJson(Map<String, dynamic> json) {
    return NetworkInfoModel(
      connectionType: json['connectionType'] as String,
      wifiName: json['wifiName'] as String?,
      wifiFrequency: json['wifiFrequency'] as String?,
      wifiSignalStrength: json['wifiSignalStrength'] as int?,
      wifiLinkSpeed: json['wifiLinkSpeed'] as int?,
      wifiBSSID: json['wifiBSSID'] as String?,
      externalIP: json['externalIP'] as String?,
      internalIP: json['internalIP'] as String?,
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

  factory SpeedTestResultModel.fromEntity(SpeedTestResultEntity entity) {
    return SpeedTestResultModel(
      downloadSpeed: entity.downloadSpeed,
      uploadSpeed: entity.uploadSpeed,
      ping: entity.ping,
      jitter: entity.jitter,
      serverLocation: entity.serverLocation,
      testStartTime: entity.testStartTime,
      testEndTime: entity.testEndTime,
      testCompleted: entity.testCompleted,
      errorMessage: entity.errorMessage,
    );
  }

  factory SpeedTestResultModel.fromJson(Map<String, dynamic> json) {
    return SpeedTestResultModel(
      downloadSpeed: (json['downloadSpeed'] as num?)?.toDouble() ?? 0.0,
      uploadSpeed: (json['uploadSpeed'] as num?)?.toDouble() ?? 0.0,
      ping: (json['ping'] as num?)?.toDouble() ?? 0.0,
      jitter: (json['jitter'] as num?)?.toDouble() ?? 0.0,
      serverLocation: json['serverLocation'] as String? ?? '',
      testStartTime: DateTime.parse(json['testStartTime']),
      testEndTime: DateTime.parse(json['testEndTime']),
      testCompleted: json['testCompleted'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
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