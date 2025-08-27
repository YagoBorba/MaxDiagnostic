import 'package:equatable/equatable.dart';

import 'final_results_entity.dart';

abstract class DiagnosticFlowEvent extends Equatable {
  const DiagnosticFlowEvent();
}

class DiagnosticProgressUpdate extends DiagnosticFlowEvent {
  final DiagnosticProgressEntity progress;

  const DiagnosticProgressUpdate(this.progress);

  @override
  List<Object?> get props => [progress];
}

class DiagnosticCompleted extends DiagnosticFlowEvent {
  final FinalResultsEntity results;

  const DiagnosticCompleted(this.results);

  @override
  List<Object?> get props => [results];
}
