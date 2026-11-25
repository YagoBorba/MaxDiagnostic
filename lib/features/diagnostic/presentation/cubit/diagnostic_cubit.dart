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

  static const int _capacityCheckPollingSeconds = 5;

  Future<void> startTest() async {
    await _sub?.cancel();
    emit(state.copyWith(
      globalStatus: GlobalTestStatus.running,
      currentStage: DiagnosticStage.initializing,
      finalResults: null,
      errorMessage: null,
      clearError: true,
      clearFinalResults: true,
      tests: DiagnosticState.initial().tests,
      overallProgress: 0.0,
      clearQueue: true,
    ));

    await _runDiagnosticLoop();
  }

  Future<void> _runDiagnosticLoop() async {
    while (!isClosed) {
      final eitherStream = await runDiagnosticTestUseCase(const NoParams());
      if (eitherStream.isLeft()) {
        _handleFailure(eitherStream.swap().getOrElse(
            () => const ServerFailure(message: 'Falha ao iniciar o diagnóstico.')));
        return;
      }

      final stream = eitherStream.getOrElse(
        () => const Stream<Either<Failure, DiagnosticFlowEvent>>.empty(),
      );

      bool shouldRetry = false;
      int waitSeconds = _capacityCheckPollingSeconds;
      bool sawTerminalEvent = false;
      final completer = Completer<void>();

      _sub = stream.listen(
        (either) {
          either.fold(
            (failure) {
              sawTerminalEvent = true;
              shouldRetry = false;
              if (!completer.isCompleted) {
                _handleFailure(failure);
                completer.complete();
              }
            },
            (event) {
              if (event is DiagnosticQueueing) {
                sawTerminalEvent = true;
                final wait = event.estimatedWaitSeconds > 0
                    ? event.estimatedWaitSeconds
                    : _capacityCheckPollingSeconds;
                waitSeconds = wait;
                shouldRetry = true;
                _emitQueueState(wait, event.message);
                if (!completer.isCompleted) {
                  completer.complete();
                }
                return;
              }

              if (event is DiagnosticProgressEntity) {
                _applyProgress(event);
                return;
              }

              if (event is DiagnosticCompleted) {
                sawTerminalEvent = true;
                shouldRetry = false;
                _handleTestCompletion(event);
                if (!completer.isCompleted) {
                  completer.complete();
                }
              }
            },
          );
        },
        onError: (error) {
          sawTerminalEvent = true;
          if (!completer.isCompleted) {
            _handleFailure(
              ServerFailure(message: 'Erro inesperado no stream: $error'),
            );
            completer.complete();
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            if (!sawTerminalEvent) {
              _handleFailure(const ServerFailure(
                  message: 'O teste foi interrompido inesperadamente.'));
            }
            completer.complete();
          }
        },
      );

      await completer.future;
      await _sub?.cancel();
      _sub = null;
      _disposeResourcesSafely();

      if (!shouldRetry) {
        break;
      }

      const int gracePeriodSeconds = 2;
      final delaySeconds =
          waitSeconds > 0 ? waitSeconds : _capacityCheckPollingSeconds;
      await Future.delayed(
        Duration(seconds: delaySeconds + gracePeriodSeconds),
      );
    }
  }

  void _emitQueueState(int waitSeconds, String backendMessage) {
    debugPrint('ℹ️ Fila de capacidade: $backendMessage (retry em ${waitSeconds}s)');
    emit(state.copyWith(
      globalStatus: GlobalTestStatus.running,
      currentStage: DiagnosticStage.startingSpeedTest,
      isQueued: true,
      queueWaitSeconds: waitSeconds,
      queueMessage: null,
      clearError: true,
    ));
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
      clearQueue: true,
    ));
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
      clearQueue: true,
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
        clearQueue: true,
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
      clearQueue: true,
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