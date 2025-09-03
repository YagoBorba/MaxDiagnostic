import 'dart:async';
import 'package:dartz/dartz.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/final_results_entity.dart';
import '../../domain/repositories/diagnostic_repository.dart';
import '../../domain/entities/diagnostic_flow.dart';
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
  Stream<Either<Failure, DiagnosticFlowEvent>> runDiagnosticTest() async* {
    try {
      if (!await networkInfo.isConnected) {
        yield const Left(NetworkFailure('No network connection available'));
        return;
      }

      // Helper function to reduce boilerplate
      Stream<Either<Failure, DiagnosticFlowEvent>> yieldProgress( // NOME CORRIGIDO
        DiagnosticStage stage, double progress, String message) async* {
          yield Right(DiagnosticProgressUpdate(DiagnosticProgressModel(
            stage: stage, progress: progress, message: message, timestamp: DateTime.now())));
      }

      yield* yieldProgress(DiagnosticStage.initializing, 0.0, 'Iniciando diagnóstico...');

      yield* yieldProgress(DiagnosticStage.collectingDeviceInfo, 0.1, 'Coletando informações do dispositivo...');
      final deviceInfo = await deviceInfoLocalDataSource.getDeviceInfo();

      yield* yieldProgress(DiagnosticStage.collectingNetworkInfo, 0.2, 'Coletando informações de rede...');
      final initialNetworkInfo = await networkInfoLocalDataSource.getNetworkInfo();

      final progressStream = speedTestRemoteDataSource.runSpeedTest();

      await for (final progressResult in progressStream) {
        yield Right(DiagnosticProgressUpdate(progressResult));

        if (progressResult.stage == DiagnosticStage.completed) {
          final speedResult = await speedTestRemoteDataSource.getSpeedTestResult();
          final finalNetworkInfo = await networkInfoLocalDataSource.getNetworkInfo();

          final finalResults = FinalResultsModel(
            timestamp: DateTime.now(),
            deviceInfo: deviceInfo,
            networkInfo: finalNetworkInfo.wifiName != null ? finalNetworkInfo : initialNetworkInfo,
            speedTestResult: speedResult,
          );
          
          yield Right(DiagnosticCompleted(finalResults));
          return; // Use return to exit the generator cleanly
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
    } finally {
      // Ensure datasource resources are cleaned up, especially if the stream is cancelled from UI
      speedTestRemoteDataSource.dispose();
    }
  }

  @override
  Future<Either<Failure, NetworkInfoEntity>> getInitialNetworkInfo() async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        return const Left(NetworkFailure('No network connection available'));
      }
      final networkInfoModel = await networkInfoLocalDataSource.getInitialNetworkInfo();
      return Right(networkInfoModel);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (e) {
      return Left(NetworkFailure('Failed to get network info: ${e.toString()}'));
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
      return Left(DeviceInfoFailure('Failed to get device info: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, NetworkInfoEntity>> getNetworkInfo() async {
    try {
      final networkInfoModel = await networkInfoLocalDataSource.getNetworkInfo();
      return Right(networkInfoModel);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (e) {
      return Left(NetworkFailure('Failed to get network info: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SpeedTestResultEntity>> runSpeedTest() async {
    try {
      final speedTestResult = await speedTestRemoteDataSource.getSpeedTestResult();
      return Right(speedTestResult);
    } on SpeedTestException catch (e) {
      return Left(SpeedTestFailure(e.message));
    } catch (e) {
      return Left(SpeedTestFailure('Speed test failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveDiagnosticResults(FinalResultsEntity results) async {
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
  Future<Either<Failure, String>> generatePdfReport(FinalResultsEntity results) async {
    try {
      return const Right('/path/to/generated/report.pdf');
    } catch (e) {
      return Left(ServerFailure('Failed to generate PDF: ${e.toString()}'));
    }
  }
}