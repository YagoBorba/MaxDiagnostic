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
  }) : _progressCalculator = progressCalculator ?? ProgressCalculator.defaultConfig(),
        super(DiagnosticState.initial());

  Future<void> startTest() async {
    _sub?.cancel();
    emit(DiagnosticState.initial().copyWith(
      globalStatus: GlobalTestStatus.running,
    ));

    final eitherStream = await runDiagnosticTestUseCase(const NoParams());
    eitherStream.fold((failure) {
      _handleFailure(failure);
    }, (stream) {
      _sub = stream.listen(
        (Either<Failure, DiagnosticFlowEvent> either) {
          either.fold(
            (failure) => _handleFailure(failure),
            (event) => _handleDiagnosticEvent(event),
          );
        },
        onError: (error) {
          debugPrint('❌ Erro inesperado no Stream do diagnóstico: $error');
          _handleStreamError(error);
        },
        onDone: () {
          debugPrint('✅ Stream do diagnóstico finalizado');
          _handleStreamDone();
        },
      );
    });
  }

  void _handleFailure(Failure failure) {
    String errorMessage = 'Erro desconhecido no diagnóstico';
    if (failure is ServerFailure) {
      errorMessage = failure.message;
    } else if (failure is NetworkFailure) {
      errorMessage = failure.message;
    } else if (failure is SpeedTestFailure) {
      errorMessage = failure.message;
    }
    
    debugPrint('❌ Falha no diagnóstico: $errorMessage');
    emit(state.copyWith(
      globalStatus: GlobalTestStatus.error,
      tests: state.tests.map((t) => t.copyWith(status: TestStatus.error)).toList(),
    ));
  }

  void _handleDiagnosticEvent(DiagnosticFlowEvent event) {
    if (event is DiagnosticProgressUpdate) {
      _applyProgress(event.progress);
    } else if (event is DiagnosticCompleted) {
      _handleTestCompletion(event);
    }
  }

  void _handleStreamError(dynamic error) {
    emit(state.copyWith(
      globalStatus: GlobalTestStatus.error,
      tests: state.tests.map((t) => t.copyWith(status: TestStatus.error)).toList(),
    ));
  }

  void _handleStreamDone() {
    if (state.globalStatus != GlobalTestStatus.complete) {
      debugPrint('⚠️ Stream finalizado sem conclusão adequada. Status atual: ${state.globalStatus}');
      emit(state.copyWith(
        globalStatus: GlobalTestStatus.error,
        tests: state.tests.map((t) => 
          t.status == TestStatus.running 
            ? t.copyWith(status: TestStatus.error)
            : t
        ).toList(),
      ));
    }
  }

  void _handleTestCompletion(DiagnosticCompleted event) {
    emit(state.copyWith(
      globalStatus: GlobalTestStatus.complete,
      overallProgress: 100,
      tests: state.tests
          .map((t) => t.copyWith(status: TestStatus.complete, progress: 1))
          .toList(),
      finalResults: event.results,
    ));
  }

  void _applyProgress(DiagnosticProgressEntity p) {
  final overall = _progressCalculator.calculateOverallProgress(p.stage, p.progress);
    
    List<TestUIState> updated = state.tests;
    

    switch (p.stage) {
      case DiagnosticStage.runningDownloadTest:
        updated = _updateTest('download', TestStatus.running, p.message, p.progress);
        break;
      case DiagnosticStage.runningUploadTest:
        updated = _updateTest('upload', TestStatus.running, p.message, p.progress);
        break;
      case DiagnosticStage.runningLatencyTest:
        updated = _updateTest('latency', TestStatus.running, p.message, p.progress);
        break;
      case DiagnosticStage.collectingDeviceInfo:
        updated = _updateTest('additionalInfo', TestStatus.collecting, 'Coletando informações do dispositivo...', p.progress);
        break;
      case DiagnosticStage.collectingNetworkInfo:
        updated = _updateTest('additionalInfo', TestStatus.collecting, 'Coletando informações de rede...', p.progress);
        break;
      case DiagnosticStage.completed:
        updated = state.tests.map((t) => t.copyWith(status: TestStatus.complete, progress: 1.0)).toList();
        break;
      case DiagnosticStage.error:
        updated = state.tests.map((t) => t.copyWith(status: TestStatus.error)).toList();
        break;
      default:
        // Para outros estágios, mantém o estado atual dos testes
        break;
    }

    emit(state.copyWith(
      overallProgress: overall,
      tests: updated,
    ));
  }

  List<TestUIState> _updateTest(String id, TestStatus status, String text, [double? progress]) {
    return state.tests.map((t) {
      if (t.id == id) {
        return t.copyWith(
          status: status, 
          resultText: text,
          progress: progress ?? t.progress,
        );
      }
      return t;
    }).toList();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
