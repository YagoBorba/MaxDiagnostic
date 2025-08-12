// lib/features/diagnostic/presentation/cubit/diagnostic_state.dart
part of 'diagnostic_cubit.dart';

enum GlobalTestStatus { pending, running, complete, error }

class DiagnosticState extends Equatable {
  // Este estado espelha as variáveis de estado do hook `useDiagnosticTests`
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
    // TODO: Criar uma função para gerar o estado inicial dos testes
    return const DiagnosticState(
      tests: [], // Placeholder
      overallProgress: 0.0,
      globalStatus: GlobalTestStatus.pending,
      isWebViewReady: false,
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
    return DiagnosticState(
      tests: tests ?? this.tests,
      overallProgress: overallProgress ?? this.overallProgress,
      globalStatus: globalStatus ?? this.globalStatus,
      isWebViewReady: isWebViewReady ?? this.isWebViewReady,
      webViewErrorMessage: webViewErrorMessage ?? this.webViewErrorMessage,
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

// Representação do TestUIState em Dart
class TestUIState extends Equatable {
  final String id;
  final String name;
  final String status;
  final double progress;
  final String? resultText;

  const TestUIState({
    required this.id,
    required this.name,
    required this.status,
    required this.progress,
    this.resultText,
  });

  @override
  List<Object?> get props => [id, name, status, progress, resultText];
}
