import 'package:equatable/equatable.dart';
import 'final_results_entity.dart';
import '../../data/models/speed_test_result_model.dart';
import '../../data/models/ping_result_model.dart';

enum DiagnosticStage {
  initializing,
  collectingDeviceInfo,
  collectingNetworkInfo,
  startingSpeedTest,
  runningDownloadTest,
  runningUploadTest,
  runningLatencyTest,
  runningPingTest,
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
        return 'Testando latência e jitter...';
      case DiagnosticStage.runningPingTest:
        return 'Medindo latência e perda de pacotes...';
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
  final PingResultEntity? pingResult;

  const DiagnosticProgressEntity({
    required this.stage,
    required this.progress,
    required this.message,
    required this.timestamp,
    this.speedTestResult,
    this.pingResult,
  });

  @override
  List<Object?> get props => [stage, progress, message, timestamp, speedTestResult, pingResult];
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
    super.pingResult,
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
      // Assuming speedTestResult might be part of the progress JSON
      speedTestResult: json['speedTestResult'] != null
          ? SpeedTestResultModel.fromJson(json['speedTestResult'])
          : null,
      pingResult: json['pingResult'] != null
          ? PingResultModel.fromJson(json['pingResult'])
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
      'pingResult': pingResult != null ? (pingResult as PingResultModel).toJson() : null,
    };
  }
}