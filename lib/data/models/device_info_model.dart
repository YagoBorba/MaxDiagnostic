import '../../domain/entities/final_results_entity.dart';

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