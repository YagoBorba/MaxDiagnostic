import '../../domain/entities/final_results_entity.dart';

class PingResultModel extends PingResultEntity {
  const PingResultModel({
    required super.averageLatencyMs,
    required super.minLatencyMs,
    required super.maxLatencyMs,
    required super.jitterMs,
    required super.packetLossPercentage,
    required super.transmitted,
    required super.received,
    super.samplesMs = const [],
  });

  const PingResultModel.empty()
      : super(
          averageLatencyMs: 0,
          minLatencyMs: 0,
          maxLatencyMs: 0,
          jitterMs: 0,
          packetLossPercentage: 0,
          transmitted: 0,
          received: 0,
          samplesMs: const [],
        );

  factory PingResultModel.fromEntity(PingResultEntity entity) {
    return PingResultModel(
      averageLatencyMs: entity.averageLatencyMs,
      minLatencyMs: entity.minLatencyMs,
      maxLatencyMs: entity.maxLatencyMs,
      jitterMs: entity.jitterMs,
      packetLossPercentage: entity.packetLossPercentage,
      transmitted: entity.transmitted,
      received: entity.received,
      samplesMs: List<double>.from(entity.samplesMs),
    );
  }

  factory PingResultModel.fromJson(Map<String, dynamic> json) {
    return PingResultModel(
      averageLatencyMs: (json['averageLatencyMs'] as num?)?.toDouble() ?? 0.0,
      minLatencyMs: (json['minLatencyMs'] as num?)?.toDouble() ?? 0.0,
      maxLatencyMs: (json['maxLatencyMs'] as num?)?.toDouble() ?? 0.0,
      jitterMs: (json['jitterMs'] as num?)?.toDouble() ?? 0.0,
      packetLossPercentage: (json['packetLossPercentage'] as num?)?.toDouble() ?? 0.0,
      transmitted: json['transmitted'] as int? ?? 0,
      received: json['received'] as int? ?? 0,
      samplesMs: (json['samplesMs'] as List<dynamic>?)
              ?.map((value) => (value as num).toDouble())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageLatencyMs': averageLatencyMs,
      'minLatencyMs': minLatencyMs,
      'maxLatencyMs': maxLatencyMs,
      'jitterMs': jitterMs,
      'packetLossPercentage': packetLossPercentage,
      'transmitted': transmitted,
      'received': received,
      'samplesMs': samplesMs,
    };
  }
}
