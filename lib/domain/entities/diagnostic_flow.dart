import 'package:equatable/equatable.dart';
import 'final_results_entity.dart';
import '../../data/models/speed_test_result_model.dart';

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

abstract class DiagnosticFlowEvent extends Equatable {
  const DiagnosticFlowEvent();

  @override
  List<Object?> get props => [];
}

class DiagnosticProgressEntity extends DiagnosticFlowEvent {
  final DiagnosticStage stage;
  final double progress;
  final String message;
  final DateTime timestamp;
  final SpeedTestResultEntity? speedTestResult;

  const DiagnosticProgressEntity({
    required this.stage,
    required this.progress,
    required this.message,
    required this.timestamp,
    this.speedTestResult,
  });

  @override
  List<Object?> get props => [stage, progress, message, timestamp, speedTestResult];
}

class DiagnosticCompleted extends DiagnosticFlowEvent {
  final FinalResultsEntity results;

  const DiagnosticCompleted(this.results);

  @override
  List<Object?> get props => [results];
}

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
      'speedTestResult': speedTestResult != null ? (speedTestResult as SpeedTestResultModel).toJson() : null,
    };
  }
}