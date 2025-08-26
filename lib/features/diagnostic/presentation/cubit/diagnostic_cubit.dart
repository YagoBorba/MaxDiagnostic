import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';

part 'diagnostic_state.dart';

class DiagnosticCubit extends Cubit<DiagnosticState> {
  DiagnosticCubit() : super(DiagnosticState.initial());

  Future<void> startMockTest() async {
    emit(DiagnosticState.initial());
    await Future.delayed(const Duration(milliseconds: 100));

    emit(state.copyWith(
      globalStatus: GlobalTestStatus.running,
      tests: state.tests.map((t) {
        if (t.id == 'download') {
          return t.copyWith(
              status: TestStatus.running, resultText: 'Iniciando...');
        }
        return t;
      }).toList(),
    ));

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      emit(state.copyWith(
        tests: state.tests.map((t) {
          if (t.id == 'download') {
            return t.copyWith(
              progress: i / 10.0,
              resultText: '${(i * 1.27).toStringAsFixed(2)} Mbps',
            );
          }
          return t;
        }).toList(),
      ));
    }

    emit(state.copyWith(
      overallProgress: 20,
      tests: state.tests.map((t) {
        if (t.id == 'download') {
          return t.copyWith(
              status: TestStatus.complete,
              progress: 1.0,
              resultText: '12.70 Mbps');
        }
        if (t.id == 'upload') {
          return t.copyWith(
              status: TestStatus.running, resultText: 'Iniciando...');
        }
        return t;
      }).toList(),
    ));

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      emit(state.copyWith(
        overallProgress: 20 + (i * 2.0),
        tests: state.tests.map((t) {
          if (t.id == 'upload') {
            return t.copyWith(
              progress: i / 10.0,
              resultText: '${(i * 2.01).toStringAsFixed(2)} Mbps',
            );
          }
          return t;
        }).toList(),
      ));
    }

    emit(state.copyWith(
      overallProgress: 90,
      globalStatus: GlobalTestStatus.complete,
      tests: state.tests.map((t) {
        switch (t.id) {
          case 'download':
            return t.copyWith(
                status: TestStatus.complete,
                progress: 1.0,
                resultText: '12.70 Mbps');
          case 'upload':
            return t.copyWith(
                status: TestStatus.complete,
                progress: 1.0,
                resultText: '20.11 Mbps');
          case 'latency':
            return t.copyWith(
                status: TestStatus.complete, resultText: '11.9 ms');
          case 'jitter':
            return t.copyWith(
                status: TestStatus.complete, resultText: '10.7 ms');
          case 'additionalInfo':
            return t.copyWith(status: TestStatus.collecting);
          default:
            return t;
        }
      }).toList(),
    ));

    await Future.delayed(const Duration(seconds: 1));

    emit(state.copyWith(
      overallProgress: 100,
      tests: state.tests
          .map((t) => t.copyWith(status: TestStatus.complete))
          .toList(),
    ));

    final mockResults = FinalResultsEntity(
      timestamp: DateTime.now(),
      deviceInfo: const DeviceInfoEntity(
        deviceModel: 'Pixel 7',
        deviceBrand: 'Google',
        operatingSystem: 'Android',
        osVersion: '14',
      ),
      networkInfo: const NetworkInfoEntity(
        connectionType: 'WiFi',
        wifiName: 'MAX-5G',
        wifiFrequency: '5 GHz',
        wifiSignalStrength: -48,
        wifiLinkSpeed: 433,
      ),
      speedTestResult: SpeedTestResultEntity(
        downloadSpeed: 12.70,
        uploadSpeed: 20.11,
        ping: 11.9,
        jitter: 10.7,
        serverLocation: 'São Paulo - BR',
        testStartTime: DateTime(2025, 1, 1, 12, 0),
        testEndTime: DateTime(2025, 1, 1, 12, 1),
        testCompleted: true,
      ),
    );

    emit(state.copyWith(finalResults: mockResults));
  }
}
