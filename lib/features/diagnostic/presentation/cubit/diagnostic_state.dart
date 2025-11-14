part of 'diagnostic_cubit.dart';

enum GlobalTestStatus { pending, running, complete, error }

enum TestStatus { pending, running, complete, error, collecting }

class TestUIState extends Equatable {
  final String id;
  final String name;
  final TestStatus status;
  final double progress;
  final String? resultText;

  const TestUIState({
    required this.id,
    required this.name,
    this.status = TestStatus.pending,
    this.progress = 0.0,
    this.resultText,
  });

  TestUIState copyWith({
    TestStatus? status,
    double? progress,
    String? resultText,
  }) {
    return TestUIState(
      id: id,
      name: name,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      resultText: resultText ?? this.resultText,
    );
  }

  @override
  List<Object?> get props => [id, name, status, progress, resultText];
}

class DiagnosticState extends Equatable {
  final Map<String, TestUIState> tests;
  final double overallProgress;
  final GlobalTestStatus globalStatus;
  final FinalResultsEntity? finalResults;
  final String? errorMessage;
  final DiagnosticStage currentStage;


  const DiagnosticState({
    required this.tests,
    required this.overallProgress,
    required this.globalStatus,
    required this.currentStage,
    this.finalResults,
    this.errorMessage,
  });

  factory DiagnosticState.initial() {
    return const DiagnosticState(
      tests: {
        'download': TestUIState(id: 'download', name: 'Teste de Download'),
        'upload': TestUIState(id: 'upload', name: 'Teste de Upload'),
        'latency': TestUIState(id: 'latency', name: 'Teste de Latência'),
        'jitter': TestUIState(id: 'jitter', name: 'Teste de Jitter'),
        'additionalInfo': TestUIState(id: 'additionalInfo', name: 'Informações Adicionais'),
      },
      overallProgress: 0.0,
      globalStatus: GlobalTestStatus.pending,
      currentStage: DiagnosticStage.initializing,
    );
  }

  DiagnosticState copyWith({
    Map<String, TestUIState>? tests,
    double? overallProgress,
    GlobalTestStatus? globalStatus,
    FinalResultsEntity? finalResults,
    String? errorMessage,
    bool clearError = false, 
    DiagnosticStage? currentStage,
  }) {
    return DiagnosticState(
      tests: tests ?? this.tests,
      overallProgress: overallProgress ?? this.overallProgress,
      globalStatus: globalStatus ?? this.globalStatus,
      finalResults: finalResults ?? this.finalResults,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      currentStage: currentStage ?? this.currentStage,
    );
  }

  @override
  List<Object?> get props => [
        tests,
        overallProgress,
        globalStatus,
        finalResults,
        errorMessage,
        currentStage,
      ];
}