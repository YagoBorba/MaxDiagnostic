import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:maxt_diagnostic/core/error/failures.dart';
import 'package:maxt_diagnostic/core/usecases/usecase.dart';
import 'package:maxt_diagnostic/domain/entities/diagnostic_flow.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';

class MockRunDiagnosticTestUseCase
    implements UseCase<Stream<Either<Failure, DiagnosticFlowEvent>>, NoParams> {
  const MockRunDiagnosticTestUseCase();

  @override
  Future<Either<Failure, Stream<Either<Failure, DiagnosticFlowEvent>>>> call(
      NoParams params) async {
    final controller = StreamController<Either<Failure, DiagnosticFlowEvent>>();

    Future<void> emitProgress(
        DiagnosticStage stage, double progress, String msg) async {
      controller.add(Right(DiagnosticProgressEntity(
        stage: stage,
        progress: progress,
        message: msg,
        timestamp: DateTime.now(),
      )));
      await Future.delayed(const Duration(milliseconds: 50));
    }

    () async {
      try {
        await emitProgress(DiagnosticStage.collectingDeviceInfo, 0.25,
            'Coletando informações do dispositivo...');
        await emitProgress(
            DiagnosticStage.collectingDeviceInfo, 1.0, 'Dispositivo coletado');

        await emitProgress(
            DiagnosticStage.collectingNetworkInfo, 0.30, 'Coletando rede...');
        await emitProgress(
            DiagnosticStage.collectingNetworkInfo, 1.0, 'Rede coletada');

        await emitProgress(
            DiagnosticStage.runningDownloadTest, 0.20, 'Download iniciando');
        await emitProgress(
            DiagnosticStage.runningDownloadTest, 1.0, 'Download finalizado');

        await emitProgress(
            DiagnosticStage.runningUploadTest, 0.30, 'Upload iniciando');
        await emitProgress(
            DiagnosticStage.runningUploadTest, 1.0, 'Upload finalizado');

        await emitProgress(
            DiagnosticStage.runningLatencyTest, 0.30, 'Latência iniciando');
        await emitProgress(
            DiagnosticStage.runningLatencyTest, 1.0, 'Latência finalizada');

        await emitProgress(DiagnosticStage.collectingAdditionalInfo, 0.50,
            'Coletando informações adicionais...');
        await emitProgress(DiagnosticStage.collectingAdditionalInfo, 1.0,
            'Informações coletadas');

        final results = FinalResultsEntity(
          timestamp: DateTime.now(),
          deviceInfo: const DeviceInfoEntity(
            deviceModel: 'MockPhone',
            deviceBrand: 'MockBrand',
            operatingSystem: 'Android',
            osVersion: '14',
          ),
          initialNetworkInfo: const NetworkInfoEntity(
            connectionType: 'WiFi',
            wifiName: 'MockWiFi',
            externalIP: '203.0.113.42',
            wifiSignalStrength: -45,
            wifiChannel: 6,
            wifiStandard: '802.11n',
            isp: 'MockISP',
          ),
          networkInfo: const NetworkInfoEntity(
            connectionType: 'WiFi',
            wifiName: 'MockWiFi',
            externalIP: '203.0.113.42',
            wifiSignalStrength: -50,
            wifiChannel: 6,
            wifiStandard: '802.11n',
            isp: 'MockISP',
          ),
          speedTestResult: SpeedTestResultEntity(
            downloadSpeed: 150.0,
            uploadSpeed: 80.0,
            ping: 15.0,
            jitter: 2.0,
            serverLocation: 'São Paulo - BR',
            testStartTime: DateTime.now().subtract(const Duration(seconds: 8)),
            testEndTime: DateTime.now(),
            testCompleted: true,
          ),
        );

        controller.add(Right(DiagnosticCompleted(results)));
      } catch (e) {
        controller.add(Left(ServerFailure(message: 'Mock error: $e')));
      } finally {
        await Future.delayed(const Duration(milliseconds: 50));
        await controller.close();
      }
    }();

    return Right(controller.stream);
  }
}