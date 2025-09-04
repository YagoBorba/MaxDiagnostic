import '../../domain/entities/final_results_entity.dart';

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connectionType': connectionType,
      'wifiName': wifiName,
    };
  }
}