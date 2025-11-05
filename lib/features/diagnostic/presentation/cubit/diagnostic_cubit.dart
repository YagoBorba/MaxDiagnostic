import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';
import 'package:maxt_diagnostic/domain/entities/diagnostic_flow.dart';
import 'package:dartz/dartz.dart';
import 'package:maxt_diagnostic/core/error/failures.dart';
import 'package:maxt_diagnostic/domain/usecases/run_diagnostic_test.dart';
import 'package:maxt_diagnostic/core/usecases/usecase.dart';
import 'package:maxt_diagnostic/features/diagnostic/presentation/utils/progress_calculator.dart';

part 'diagnostic_state.dart';

class DiagnosticCubit extends Cubit<DiagnosticState> {
  final RunDiagnosticTest runDiagnosticTestUseCase;
  final ProgressCalculator _progressCalculator;
  StreamSubscription? _sub;

  DiagnosticCubit({
    required this.runDiagnosticTestUseCase,
    ProgressCalculator? progressCalculator,
  })  : _progressCalculator = progressCalculator ?? ProgressCalculator.defaultConfig(),
        super(DiagnosticState.initial());

  static const Map<DiagnosticStage, String> _stageToTestIdMap = {
    DiagnosticStage.runningDownloadTest: 'download',
    DiagnosticStage.runningUploadTest: 'upload',
    DiagnosticStage.runningLatencyTest: 'latency',
    DiagnosticStage.collectingDeviceInfo: 'additionalInfo',
    DiagnosticStage.collectingNetworkInfo: 'additionalInfo',
  };

  Future<void> startTest() async {
    await _sub?.cancel();
    emit(DiagnosticState.initial().copyWith(
      globalStatus: GlobalTestStatus.running,
    ));

    final eitherStream = await runDiagnosticTestUseCase(const NoParams());
    eitherStream.fold(
      (failure) => _handleFailure(failure),
      (stream) {
        _sub = stream.listen(
          (Either<Failure, DiagnosticFlowEvent> either) {
            either.fold(
              (failure) => _handleFailure(failure),
              (event) => _handleDiagnosticEvent(event),
            );
          },
          onError: (error) => _handleFailure(ServerFailure(message: 'Erro inesperado no stream: $error')),
          onDone: _handleStreamDone,
        );
      },
    );
  }

  void _handleFailure(Failure failure) {
    debugPrint('❌ Falha no diagnóstico: ${failure.message}');
    final updatedTests = Map.of(state.tests);
    for (var key in updatedTests.keys) {
        if(updatedTests[key]!.status == TestStatus.running) {
             updatedTests[key] = updatedTests[key]!.copyWith(status: TestStatus.error);
        }
    }
    emit(state.copyWith(
      globalStatus: GlobalTestStatus.error,
      errorMessage: failure.message,
      tests: updatedTests,
    ));
  }

  void _handleDiagnosticEvent(DiagnosticFlowEvent event) {
  if (event is DiagnosticProgressEntity) { 
    _applyProgress(event); 
  } else if (event is DiagnosticCompleted) {
    _handleTestCompletion(event);
  }
}

  void _handleStreamDone() {
    if (state.globalStatus != GlobalTestStatus.complete && state.globalStatus != GlobalTestStatus.error) {
      debugPrint('⚠️ Stream finalizado sem conclusão adequada. Marcando como erro.');
      _handleFailure(const ServerFailure(message: 'O teste foi interrompido inesperadamente.'));
    }
  }

  void _handleTestCompletion(DiagnosticCompleted event) {
    final results = event.results;
    
    final finalTests = Map.of(state.tests);
    finalTests['download'] = finalTests['download']!.copyWith(status: TestStatus.complete, progress: 1.0, resultText: '${results.speedTestResult.downloadSpeed.toStringAsFixed(2)} Mbps');
    finalTests['upload'] = finalTests['upload']!.copyWith(status: TestStatus.complete, progress: 1.0, resultText: '${results.speedTestResult.uploadSpeed.toStringAsFixed(2)} Mbps');
    finalTests['latency'] = finalTests['latency']!.copyWith(status: TestStatus.complete, progress: 1.0, resultText: '${results.speedTestResult.ping.toStringAsFixed(1)} ms');
    finalTests['jitter'] = finalTests['jitter']!.copyWith(status: TestStatus.complete, progress: 1.0, resultText: '${results.speedTestResult.jitter.toStringAsFixed(1)} ms');
    finalTests['additionalInfo'] = finalTests['additionalInfo']!.copyWith(status: TestStatus.complete, progress: 1.0, resultText: 'Concluído');


    emit(state.copyWith(
      globalStatus: GlobalTestStatus.complete,
      overallProgress: 100,
      tests: finalTests,
      finalResults: event.results,
      clearError: true, 
    ));
  }

  void _applyProgress(DiagnosticProgressEntity p) {
    final overall = _progressCalculator.calculateOverallProgress(p.stage, p.progress);
    
    final testId = _stageToTestIdMap[p.stage];
    if (testId == null) {
      emit(state.copyWith(overallProgress: overall));
      return;
    }
    
    final updatedTests = _updateTest(testId, TestStatus.running, p.message, p.progress);

    emit(state.copyWith(
      overallProgress: overall,
      tests: updatedTests,
      clearError: true, 
    ));
  }

  Map<String, TestUIState> _updateTest(String id, TestStatus status, String text, [double? progress]) {
    final newTests = Map.of(state.tests);
    final currentTest = newTests[id];
    
    if (currentTest != null) {
      newTests[id] = currentTest.copyWith(
        status: status,
        resultText: text,
        progress: progress,
      );
    }
    return newTests;
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}