import 'dart:async';
import 'package:dartz/dartz.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/final_results_entity.dart';
import '../../domain/repositories/diagnostic_repository.dart';
import '../../domain/entities/diagnostic_flow.dart';
// import '../datasources/device_info_local_datasource.dart';
import '../datasources/network_info_local_datasource.dart';
import '../datasources/device_info_local_datasource.dart';
import '../datasources/speed_test_remote_datasource.dart';
import '../models/final_results_model.dart';

class DiagnosticRepositoryImpl implements DiagnosticRepository {
  final NetworkInfoLocalDataSource networkInfoLocalDataSource;
  final SpeedTestRemoteDataSource speedTestRemoteDataSource;
  final NetworkInfo networkInfo;
  final DeviceInfoLocalDataSource deviceInfoLocalDataSource;

  DiagnosticRepositoryImpl({
    required this.networkInfoLocalDataSource,
    required this.speedTestRemoteDataSource,
    required this.networkInfo,
    required this.deviceInfoLocalDataSource,
  });

  @override
  Future<Either<Failure, NetworkInfoEntity>> getInitialNetworkInfo() async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        return const Left(NetworkFailure('No network connection available'));
      }

      final networkInfoModel =
          await networkInfoLocalDataSource.getInitialNetworkInfo();
      return Right(networkInfoModel);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (e) {
      return Left(
          NetworkFailure('Failed to get network info: ${e.toString()}'));
    }
  }

  @override
  Stream<Either<Failure, DiagnosticFlowEvent>> runDiagnosticTest() async* {
    try {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
  yield const Left(NetworkFailure('No network connection available'));
        return;
      }

  yield Right(DiagnosticProgressUpdate(DiagnosticProgressModel(
        stage: DiagnosticStage.initializing,
        progress: 0.0,
        message: 'Iniciando diagnóstico...',
        timestamp: DateTime.now(),
  )));

  yield Right(DiagnosticProgressUpdate(DiagnosticProgressModel(
        stage: DiagnosticStage.collectingDeviceInfo,
        progress: 0.1,
        message: 'Coletando informações do dispositivo...',
        timestamp: DateTime.now(),
  )));

  final deviceInfo = await deviceInfoLocalDataSource.getDeviceInfo();

  yield Right(DiagnosticProgressUpdate(DiagnosticProgressModel(
        stage: DiagnosticStage.collectingNetworkInfo,
        progress: 0.2,
        message: 'Coletando informações de rede...',
        timestamp: DateTime.now(),
  )));

      final initialNetworkInfo =
          await networkInfoLocalDataSource.getNetworkInfo();

      // Bridge progress from WebView
      final progressStream = speedTestRemoteDataSource.runSpeedTest();
      await for (final progressResult in progressStream) {
        yield Right(DiagnosticProgressUpdate(progressResult));
        if (progressResult.stage == DiagnosticStage.completed) {
          // When completed, fetch final data and emit FinalResults
          final speedResult =
              await speedTestRemoteDataSource.getSpeedTestResult();
          final finalNetworkInfo =
              await networkInfoLocalDataSource.getNetworkInfo();

          final finalResults = FinalResultsModel(
            timestamp: DateTime.now(),
            deviceInfo: deviceInfo,
            networkInfo: finalNetworkInfo.wifiName != null
                ? finalNetworkInfo
                : initialNetworkInfo,
            speedTestResult: speedResult,
          );

          // Emit final results event
          yield Right(DiagnosticCompleted(finalResults));

          // Optionally, results would be saved here (omitted)

          // After emitting completion, we can stop listening
          break;
        }
      }
    } on NetworkException catch (e) {
  yield Left(NetworkFailure(e.message));
    } on SpeedTestException catch (e) {
  yield Left(SpeedTestFailure(e.message));
    } on DeviceInfoException catch (e) {
  yield Left(DeviceInfoFailure(e.message));
    } catch (e) {
      yield Left(ServerFailure('Diagnostic test failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, DeviceInfoEntity>> getDeviceInfo() async {
    try {
  final deviceInfoModel = await deviceInfoLocalDataSource.getDeviceInfo();
  return Right(deviceInfoModel);
    } on DeviceInfoException catch (e) {
      return Left(DeviceInfoFailure(e.message));
    } catch (e) {
      return Left(
          DeviceInfoFailure('Failed to get device info: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, NetworkInfoEntity>> getNetworkInfo() async {
    try {
      final networkInfoModel =
          await networkInfoLocalDataSource.getNetworkInfo();
      return Right(networkInfoModel);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (e) {
      return Left(
          NetworkFailure('Failed to get network info: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SpeedTestResultEntity>> runSpeedTest() async {
    try {
      final speedTestResult =
          await speedTestRemoteDataSource.getSpeedTestResult();
      return Right(speedTestResult);
    } on SpeedTestException catch (e) {
      return Left(SpeedTestFailure(e.message));
    } catch (e) {
      return Left(SpeedTestFailure('Speed test failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveDiagnosticResults(
      FinalResultsEntity results) async {
    try {
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to save results: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<FinalResultsEntity>>> getSavedResults() async {
    try {
      return const Right([]);
    } catch (e) {
      return Left(CacheFailure('Failed to get saved results: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> generatePdfReport(
      FinalResultsEntity results) async {
    try {
      return const Right('/path/to/generated/report.pdf');
    } catch (e) {
      return Left(ServerFailure('Failed to generate PDF: ${e.toString()}'));
    }
  }
}
