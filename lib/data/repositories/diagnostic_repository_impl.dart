import 'dart:async';
import 'package:dartz/dartz.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/final_results_entity.dart';
import '../../domain/repositories/diagnostic_repository.dart';
import '../datasources/device_info_local_datasource.dart';
import '../datasources/network_info_local_datasource.dart';
import '../datasources/speed_test_remote_datasource.dart';
import '../models/final_results_model.dart';

/// Implementation of DiagnosticRepository
/// Coordinates data sources and handles error conversion
class DiagnosticRepositoryImpl implements DiagnosticRepository {
  final DeviceInfoLocalDataSource deviceInfoLocalDataSource;
  final NetworkInfoLocalDataSource networkInfoLocalDataSource;
  final SpeedTestRemoteDataSource speedTestRemoteDataSource;
  final NetworkInfo networkInfo;

  DiagnosticRepositoryImpl({
    required this.deviceInfoLocalDataSource,
    required this.networkInfoLocalDataSource,
    required this.speedTestRemoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, NetworkInfoEntity>> getInitialNetworkInfo() async {
    try {
      // Check network connectivity first
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        return Left(NetworkFailure('No network connection available'));
      }

      final networkInfoModel = await networkInfoLocalDataSource.getInitialNetworkInfo();
      return Right(networkInfoModel);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(NetworkFailure('Failed to get network info: ${e.toString()}'));
    }
  }

  @override
  Stream<Either<Failure, DiagnosticProgressEntity>> runDiagnosticTest() async* {
    try {
      // Check network connectivity
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        yield Left(NetworkFailure('No network connection available'));
        return;
      }

      // Emit initial progress
      yield Right(DiagnosticProgressModel(
        stage: DiagnosticStage.initializing,
        progress: 0.0,
        message: 'Iniciando diagnóstico...',
        timestamp: DateTime.now(),
      ));

      // Collect device info
      yield Right(DiagnosticProgressModel(
        stage: DiagnosticStage.collectingDeviceInfo,
        progress: 0.1,
        message: 'Coletando informações do dispositivo...',
        timestamp: DateTime.now(),
      ));

      // Collect network info
      yield Right(DiagnosticProgressModel(
        stage: DiagnosticStage.collectingNetworkInfo,
        progress: 0.2,
        message: 'Coletando informações de rede...',
        timestamp: DateTime.now(),
      ));

      // Run speed test and forward progress
      await for (final progressResult in speedTestRemoteDataSource.runSpeedTest()) {
        yield Right(progressResult);
      }

    } on NetworkException catch (e) {
      yield Left(NetworkFailure(e.message));
    } on SpeedTestException catch (e) {
      yield Left(SpeedTestFailure(e.message));
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
    // TODO: Implement local storage of diagnostic results
    // This could use SharedPreferences, SQLite, or another storage solution
    try {
      // For now, just return success
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to save results: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<FinalResultsEntity>>> getSavedResults() async {
    // TODO: Implement retrieval of saved diagnostic results
    try {
      // For now, return empty list
      return const Right([]);
    } catch (e) {
      return Left(CacheFailure('Failed to get saved results: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> generatePdfReport(FinalResultsEntity results) async {
    // TODO: Implement PDF generation using printing package
    try {
      // For now, just return a placeholder path
      return const Right('/path/to/generated/report.pdf');
    } catch (e) {
      return Left(ServerFailure('Failed to generate PDF: ${e.toString()}'));
    }
  }
}
