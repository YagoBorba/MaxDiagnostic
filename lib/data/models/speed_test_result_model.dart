import '../../domain/entities/final_results_entity.dart';

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
      downloadSpeed: (json['downloadSpeed'] as num).toDouble(),
      uploadSpeed: (json['uploadSpeed'] as num).toDouble(),
      ping: (json['ping'] as num).toDouble(),
      jitter: (json['jitter'] as num).toDouble(),
      serverLocation: json['serverLocation'],
      testStartTime: DateTime.parse(json['testStartTime']),
      testEndTime: DateTime.parse(json['testEndTime']),
      testCompleted: json['testCompleted'],
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