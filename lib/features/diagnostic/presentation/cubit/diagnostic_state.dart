part of 'diagnostic_cubit.dart';

enum GlobalTestStatus { pending, running, complete, error }

enum TestStatus { pending, running, complete, error, collecting }

class TestUIState extends Equatable {
  final String id;
  final String name;
  final TestStatus status;
  final double progress; // 0.0 to 1.0
  final String? resultText;

  const TestUIState({
    required this.id,
    required this.name,
    required this.status,
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
  final List<TestUIState> tests;
  final double overallProgress;
  final GlobalTestStatus globalStatus;
  final bool isWebViewReady;
  final String? webViewErrorMessage;
  final FinalResultsEntity? finalResults;

  const DiagnosticState({
    required this.tests,
    required this.overallProgress,
    required this.globalStatus,
    required this.isWebViewReady,
    this.webViewErrorMessage,
    this.finalResults,
  });

  factory DiagnosticState.initial() {
    return const DiagnosticState(
      tests: [
        TestUIState(
            id: 'download',
            name: 'Teste de Download',
            status: TestStatus.pending),
        TestUIState(
            id: 'upload', name: 'Teste de Upload', status: TestStatus.pending),
        TestUIState(
            id: 'latency',
            name: 'Teste de Latência',
            status: TestStatus.pending),
        TestUIState(
            id: 'jitter', name: 'Teste de Jitter', status: TestStatus.pending),
        TestUIState(
            id: 'additionalInfo',
            name: 'Coletando Informações Adicionais',
            status: TestStatus.pending),
      ],
      overallProgress: 0.0,
      globalStatus: GlobalTestStatus.pending,
      isWebViewReady: false, // Começa como falso até a WebView carregar
    );
  }

  DiagnosticState copyWith({
    List<TestUIState>? tests,
    double? overallProgress,
    GlobalTestStatus? globalStatus,
    bool? isWebViewReady,
    String? webViewErrorMessage,
    FinalResultsEntity? finalResults,
  }) {
    final newWebViewErrorMessage =
        (globalStatus != null && globalStatus != this.globalStatus)
            ? null
            : webViewErrorMessage ?? this.webViewErrorMessage;

    return DiagnosticState(
      tests: tests ?? this.tests,
      overallProgress: overallProgress ?? this.overallProgress,
      globalStatus: globalStatus ?? this.globalStatus,
      isWebViewReady: isWebViewReady ?? this.isWebViewReady,
      webViewErrorMessage: newWebViewErrorMessage,
      finalResults: finalResults ?? this.finalResults,
    );
  }

  @override
  List<Object?> get props => [
        tests,
        overallProgress,
        globalStatus,
        isWebViewReady,
        webViewErrorMessage,
        finalResults
      ];
}
