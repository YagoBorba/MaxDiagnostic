// lib/domain/entities/advice_entity.dart
import 'package:equatable/equatable.dart';

enum AdviceSeverity { info, good, warning, critical }

class AdviceEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final AdviceSeverity severity;

  const AdviceEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
  });

  @override
  List<Object?> get props => [id, title, description, severity];
}