import '../../domain/entities/final_results_entity.dart';

class NetworkInfoModel extends NetworkInfoEntity {
  const NetworkInfoModel({
    required super.connectionType,
    super.wifiName,
    super.wifiFrequency,
    super.wifiSignalStrength,
    super.wifiLinkSpeed,
    super.wifiBSSID,
    super.internalIP,
    super.externalIP,
    super.isp,
    super.wifiChannel,
    super.wifiStandard,
  });

  factory NetworkInfoModel.fromEntity(NetworkInfoEntity entity) {
    return NetworkInfoModel(
      connectionType: entity.connectionType,
      wifiName: entity.wifiName,
      wifiFrequency: entity.wifiFrequency,
      wifiSignalStrength: entity.wifiSignalStrength,
      wifiLinkSpeed: entity.wifiLinkSpeed,
      wifiBSSID: entity.wifiBSSID,
      internalIP: entity.internalIP,
      externalIP: entity.externalIP,
      isp: entity.isp,
      wifiChannel: entity.wifiChannel,
      wifiStandard: entity.wifiStandard,
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
      internalIP: json['internalIP'] as String?,
      externalIP: json['externalIP'] as String?,
      isp: json['isp'] as String?,
      wifiChannel: json['wifiChannel'] as int?,
      wifiStandard: json['wifiStandard'] as String?,
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
      'internalIP': internalIP,
      'externalIP': externalIP,
      'isp': isp,
      'wifiChannel': wifiChannel,
      'wifiStandard': wifiStandard,
    };
  }
}