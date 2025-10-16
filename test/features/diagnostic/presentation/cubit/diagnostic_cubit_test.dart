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
        controller.add(Right(DiagnosticProgressEntity(
          stage: DiagnosticStage.runningDownloadTest,
          progress: 0.6,
          message: 'down',
          timestamp: DateTime.now(),
        )));
        controller.add(Right(DiagnosticProgressEntity(
          stage: DiagnosticStage.runningPingTest,
          progress: 1.0,
          message: 'Latência média 20.0 ms',
          timestamp: DateTime.now(),
          pingResult: const PingResultEntity(
            averageLatencyMs: 20.0,
            minLatencyMs: 18.0,
            maxLatencyMs: 25.0,
            jitterMs: 3.0,
            packetLossPercentage: 0.0,
            transmitted: 5,
            received: 5,
          ),
        )));
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
          pingResult: const PingResultEntity(
            averageLatencyMs: 20.0,
            minLatencyMs: 18.0,
            maxLatencyMs: 25.0,
            jitterMs: 3.0,
            packetLossPercentage: 0.0,
            transmitted: 5,
            received: 5,
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
      final download = c.state.tests['download'];
      expect(download, isNotNull);
      expect(download!.status, isNot(TestStatus.pending));
      final latency = c.state.tests['latency'];
      expect(latency?.resultText, contains('20.0 ms'));
      final jitter = c.state.tests['jitter'];
      expect(jitter?.resultText, contains('3.0 ms'));
      final info = c.state.tests['additionalInfo'];
      expect(info?.resultText, contains('Perda'));
    },
  );

  blocTest<DiagnosticCubit, DiagnosticState>(
    'emits error state when usecase returns Left',
    build: () {
    when(() => usecase(const NoParams()))
      .thenAnswer((_) async => const Left(ServerFailure(message: 'x')));
      return cubit;
    },
    act: (c) => c.startTest(),
    verify: (c) {
      expect(c.state.globalStatus, GlobalTestStatus.error);
    },
  );
}
