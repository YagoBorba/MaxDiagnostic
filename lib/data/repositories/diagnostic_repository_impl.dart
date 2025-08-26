import 'dart:async';
import 'package:dartz/dartz.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/final_results_entity.dart';
import '../../domain/repositories/diagnostic_repository.dart';
// import '../datasources/device_info_local_datasource.dart';
import '../datasources/network_info_local_datasource.dart';
import '../datasources/speed_test_remote_datasource.dart';
import '../models/final_results_model.dart';

class DiagnosticRepositoryImpl implements DiagnosticRepository {
  final NetworkInfoLocalDataSource networkInfoLocalDataSource;
  final SpeedTestRemoteDataSource speedTestRemoteDataSource;
  final NetworkInfo networkInfo;

  DiagnosticRepositoryImpl({
    required this.networkInfoLocalDataSource,
    required this.speedTestRemoteDataSource,
    required this.networkInfo,
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
  Stream<Either<Failure, DiagnosticProgressEntity>> runDiagnosticTest() async* {
    try {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        yield const Left(NetworkFailure('No network connection available'));
        return;
      }

      yield Right(DiagnosticProgressModel(
        stage: DiagnosticStage.initializing,
        progress: 0.0,
        message: 'Iniciando diagnóstico...',
        timestamp: DateTime.now(),
      ));

      yield Right(DiagnosticProgressModel(
        stage: DiagnosticStage.collectingDeviceInfo,
        progress: 0.1,
        message: 'Coletando informações do dispositivo...',
        timestamp: DateTime.now(),
      ));

      yield Right(DiagnosticProgressModel(
        stage: DiagnosticStage.collectingNetworkInfo,
        progress: 0.2,
        message: 'Coletando informações de rede...',
        timestamp: DateTime.now(),
      ));

      await for (final progressResult
          in speedTestRemoteDataSource.runSpeedTest()) {
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
      // TODO: Re-enable when data sources are implemented
      // final deviceInfoModel = await deviceInfoLocalDataSource.getDeviceInfo();
      // return Right(deviceInfoModel);

      const mockDeviceInfo = DeviceInfoEntity(
        deviceModel: 'Loading...',
        deviceBrand: 'Loading...',
        operatingSystem: 'Loading...',
        osVersion: 'Loading...',
      );
      return const Right(mockDeviceInfo);
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
