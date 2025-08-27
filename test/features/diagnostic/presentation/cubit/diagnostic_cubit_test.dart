import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:maxt_diagnostic/core/error/failures.dart';
import 'package:maxt_diagnostic/core/usecases/usecase.dart';
import 'package:maxt_diagnostic/domain/entities/diagnostic_flow.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';
import 'package:maxt_diagnostic/domain/usecases/run_diagnostic_test.dart';
import 'package:maxt_diagnostic/features/diagnostic/presentation/cubit/diagnostic_cubit.dart';

class _MockRunDiagnosticTest extends Mock implements RunDiagnosticTest {}

void main() {
  late _MockRunDiagnosticTest usecase;
  late DiagnosticCubit cubit;

  setUp(() {
    usecase = _MockRunDiagnosticTest();
    cubit = DiagnosticCubit(runDiagnosticTestUseCase: usecase);
  });

  tearDown(() async {
    await cubit.close();
  });

  blocTest<DiagnosticCubit, DiagnosticState>(
    'progress events update overall and tests; completed sets finalResults',
    build: () {
      final controller = StreamController<Either<Failure, DiagnosticFlowEvent>>();
      when(() => usecase(const NoParams()))
          .thenAnswer((_) async => Right(controller.stream));

    Future.microtask(() {
  controller.add(Right(DiagnosticProgressUpdate(DiagnosticProgressEntity(
          stage: DiagnosticStage.runningDownloadTest,
          progress: 0.6,
          message: 'down',
          timestamp: DateTime.now(),
  ))));
        controller.add(Right(DiagnosticCompleted(FinalResultsEntity(
          timestamp: DateTime.now(),
          deviceInfo: const DeviceInfoEntity(
            deviceModel: 'X',
            deviceBrand: 'Y',
            operatingSystem: 'Android',
            osVersion: '14',
          ),
          networkInfo: const NetworkInfoEntity(connectionType: 'WiFi'),
          speedTestResult: SpeedTestResultEntity(
            downloadSpeed: 1,
            uploadSpeed: 1,
            ping: 1,
            jitter: 1,
            serverLocation: 'SP',
            testStartTime: DateTime(2020),
            testEndTime: DateTime(2020, 1, 1, 0, 1),
            testCompleted: true,
          ),
        ))));
      });
      return cubit;
    },
    act: (c) => c.startTest(),
    wait: const Duration(milliseconds: 50),
    verify: (c) {
      expect(c.state.globalStatus, GlobalTestStatus.complete);
      expect(c.state.finalResults, isNotNull);
      final download = c.state.tests.firstWhere((t) => t.id == 'download');
      expect(download.status, isNot(TestStatus.pending));
    },
  );

  blocTest<DiagnosticCubit, DiagnosticState>(
    'emits error state when usecase returns Left',
    build: () {
    when(() => usecase(const NoParams()))
      .thenAnswer((_) async => const Left(ServerFailure('x')));
      return cubit;
    },
    act: (c) => c.startTest(),
    verify: (c) {
      expect(c.state.globalStatus, GlobalTestStatus.error);
    },
  );
}
