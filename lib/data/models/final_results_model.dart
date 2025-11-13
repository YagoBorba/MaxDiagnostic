import '../../domain/entities/final_results_entity.dart';
import 'device_info_model.dart';
import 'network_info_model.dart';
import 'speed_test_result_model.dart';

export 'device_info_model.dart';
export 'network_info_model.dart';
export 'speed_test_result_model.dart';

class FinalResultsModel extends FinalResultsEntity {
  const FinalResultsModel({
    required super.timestamp,
    required DeviceInfoModel super.deviceInfo,
    required NetworkInfoModel super.networkInfo,
    required NetworkInfoModel super.initialNetworkInfo,
    required SpeedTestResultModel super.speedTestResult,
  });

  factory FinalResultsModel.fromJson(Map<String, dynamic> json) {
    return FinalResultsModel(
      timestamp: DateTime.parse(json['timestamp']),
      deviceInfo: DeviceInfoModel.fromJson(json['deviceInfo']),
      networkInfo: NetworkInfoModel.fromJson(json['networkInfo']),
      initialNetworkInfo: NetworkInfoModel.fromJson(json['initialNetworkInfo']),
      speedTestResult: SpeedTestResultModel.fromJson(json['speedTestResult']),
    );
  }

  factory FinalResultsModel.fromEntity(FinalResultsEntity entity) {
    return FinalResultsModel(
      timestamp: entity.timestamp,
      deviceInfo: DeviceInfoModel.fromEntity(entity.deviceInfo),
      networkInfo: NetworkInfoModel.fromEntity(entity.networkInfo),
      initialNetworkInfo: NetworkInfoModel.fromEntity(entity.initialNetworkInfo),
      speedTestResult: SpeedTestResultModel.fromEntity(entity.speedTestResult),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'deviceInfo': (deviceInfo as DeviceInfoModel).toJson(),
      'networkInfo': (networkInfo as NetworkInfoModel).toJson(),
      'initialNetworkInfo': (initialNetworkInfo as NetworkInfoModel).toJson(),
      'speedTestResult': (speedTestResult as SpeedTestResultModel).toJson(),
    };
  }
}
