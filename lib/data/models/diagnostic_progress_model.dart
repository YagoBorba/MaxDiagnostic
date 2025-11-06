import '../../domain/entities/diagnostic_flow.dart';
import 'speed_test_result_model.dart';

class DiagnosticProgressModel extends DiagnosticProgressEntity {
  const DiagnosticProgressModel({
    required super.stage,
    required super.progress,
    required super.message,
    required super.timestamp,
    super.speedTestResult,
  });

  factory DiagnosticProgressModel.fromJson(Map<String, dynamic> json) {
    return DiagnosticProgressModel(
      stage: DiagnosticStage.values.firstWhere(
        (e) => e.toString() == json['stage'],
        orElse: () => DiagnosticStage.initializing,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      speedTestResult: json['speedTestResult'] != null
          ? SpeedTestResultModel.fromJson(json['speedTestResult'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage': stage.toString(),
      'progress': progress,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'speedTestResult': speedTestResult != null
          ? (speedTestResult as SpeedTestResultModel).toJson()
          : null,
    };
  }
}
