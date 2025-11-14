import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';
import 'package:maxt_diagnostic/domain/entities/diagnostic_flow.dart';
import 'package:dartz/dartz.dart';
import 'package:maxt_diagnostic/core/error/failures.dart';
import 'package:maxt_diagnostic/domain/usecases/run_diagnostic_test.dart';
import 'package:maxt_diagnostic/domain/repositories/diagnostic_repository.dart';
import 'package:maxt_diagnostic/core/usecases/usecase.dart';
import 'package:maxt_diagnostic/features/diagnostic/presentation/utils/progress_calculator.dart';

part 'diagnostic_state.dart';

class DiagnosticCubit extends Cubit<DiagnosticState> {
  final RunDiagnosticTest runDiagnosticTestUseCase;
  final ProgressCalculator _progressCalculator;
  final DiagnosticRepository diagnosticRepository;
  StreamSubscription? _sub;

  DiagnosticCubit({
    required this.runDiagnosticTestUseCase,
    required this.diagnosticRepository,
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
      currentStage: DiagnosticStage.initializing,
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
          onError: (error) {
            _handleFailure(ServerFailure(message: 'Erro inesperado no stream: $error'));
            _disposeResourcesSafely();
          },
          onDone: () {
            _handleStreamDone();
            _disposeResourcesSafely();
          },
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
      currentStage: DiagnosticStage.error,
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
      currentStage: DiagnosticStage.completed,
    ));
  }

  void _disposeResourcesSafely() {
    try {
      diagnosticRepository.disposeResources();
    } catch (_) {
      // errors
    }
  }

  void _applyProgress(DiagnosticProgressEntity p) {
    final overall = _progressCalculator.calculateOverallProgress(p.stage, p.progress);
    
    final testId = _stageToTestIdMap[p.stage];
    if (testId == null) {
      emit(state.copyWith(
        overallProgress: overall,
        currentStage: p.stage,
      ));
      return;
    }
    
    final updatedTests = Map.of(state.tests);
    final isCurrentComplete = p.progress >= 1.0;

    updatedTests.updateAll((key, test) {
      if (key == testId) {
        return test;
      }

      if (test.status == TestStatus.running) {
        final finished = test.progress >= 1.0;
        return test.copyWith(status: finished ? TestStatus.complete : TestStatus.collecting);
      }

      return test;
    });

    final current = updatedTests[testId];
    if (current != null) {
      updatedTests[testId] = current.copyWith(
        status: isCurrentComplete ? TestStatus.complete : TestStatus.running,
        resultText: p.message,
        progress: p.progress,
      );
    }

    emit(state.copyWith(
      overallProgress: overall,
      tests: updatedTests,
      clearError: true, 
      currentStage: p.stage,
    ));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _disposeResourcesSafely();
    return super.close();
  }
}