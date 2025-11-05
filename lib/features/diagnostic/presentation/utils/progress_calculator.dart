import 'package:equatable/equatable.dart';
import 'package:maxt_diagnostic/domain/entities/diagnostic_flow.dart';

class StageConfig extends Equatable {
  final double startProgress;
  final double weight;

  const StageConfig({required this.startProgress, required this.weight});

  @override
  List<Object?> get props => [startProgress, weight];

  @override
  String toString() => 'StageConfig(start: $startProgress, weight: $weight)';
}

class ProgressCalculator extends Equatable {
  final Map<DiagnosticStage, StageConfig> _config;

  const ProgressCalculator._(this._config);

  factory ProgressCalculator.defaultConfig() {
    return ProgressCalculator.custom(const {
      DiagnosticStage.initializing: StageConfig(startProgress: 0.0, weight: 5.0),
      DiagnosticStage.collectingDeviceInfo: StageConfig(startProgress: 5.0, weight: 5.0),
      DiagnosticStage.collectingNetworkInfo: StageConfig(startProgress: 10.0, weight: 5.0),
      DiagnosticStage.startingSpeedTest: StageConfig(startProgress: 15.0, weight: 5.0),
      DiagnosticStage.runningDownloadTest: StageConfig(startProgress: 20.0, weight: 20.0),
      DiagnosticStage.runningUploadTest: StageConfig(startProgress: 40.0, weight: 20.0),
      DiagnosticStage.runningLatencyTest: StageConfig(startProgress: 60.0, weight: 10.0),
      DiagnosticStage.runningJitterTest: StageConfig(startProgress: 70.0, weight: 10.0),
      DiagnosticStage.collectingAdditionalInfo: StageConfig(startProgress: 80.0, weight: 15.0),
      DiagnosticStage.completed: StageConfig(startProgress: 95.0, weight: 5.0),
    });
  }

  factory ProgressCalculator.custom(Map<DiagnosticStage, StageConfig> config) {
    _validate(config);
    return ProgressCalculator._(Map.unmodifiable(config));
  }

  double calculateOverallProgress(DiagnosticStage stage, double stageProgress) {
    final cfg = _config[stage];
    if (cfg == null) return stage == DiagnosticStage.completed ? 100.0 : 0.0;
    final p = stageProgress.clamp(0.0, 1.0);
    return (cfg.startProgress + cfg.weight * p).clamp(0.0, 100.0);
  }

  double getStageStartProgress(DiagnosticStage stage) =>
      _config[stage]?.startProgress ?? 0.0;
  double getStageWeight(DiagnosticStage stage) => _config[stage]?.weight ?? 0.0;
  Set<DiagnosticStage> get configuredStages => _config.keys.toSet();
  bool isConfigurationValid() =>
      (_config.values.fold(0.0, (a, b) => a + b.weight) - 100.0).abs() <= 0.01;

  static void _validate(Map<DiagnosticStage, StageConfig> cfg) {
    if (cfg.isEmpty) throw ArgumentError('Configuration cannot be empty');
    final total = cfg.values.fold(0.0, (a, b) => a + b.weight);
    if ((total - 100.0).abs() > 0.01) {
      throw ArgumentError('Weights must sum to 100.0, got $total');
    }
  }

  @override
  List<Object?> get props => [_config];
}