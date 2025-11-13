import 'dart:async';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/final_results_entity.dart';
import '../../domain/entities/diagnostic_flow.dart';
import '../../domain/repositories/diagnostic_repository.dart';
import '../datasources/network_info_local_datasource.dart';
import '../datasources/device_info_local_datasource.dart';
import '../datasources/speed_test_remote_datasource.dart';
import '../models/final_results_model.dart';

class DiagnosticRepositoryImpl implements DiagnosticRepository {
  final NetworkInfoLocalDataSource networkInfoLocalDataSource;
  final SpeedTestRemoteDataSource speedTestRemoteDataSource;
  final NetworkInfo networkInfo;
  final DeviceInfoLocalDataSource deviceInfoLocalDataSource;
  final AppConfig appConfig;

  DiagnosticRepositoryImpl({
    required this.networkInfoLocalDataSource,
    required this.speedTestRemoteDataSource,
    required this.networkInfo,
    required this.deviceInfoLocalDataSource,
    required this.appConfig,
  });

  @override
  Stream<Either<Failure, DiagnosticFlowEvent>> runDiagnosticTest() async* {
    try {
      if (!await networkInfo.isConnected) {
        yield const Left(NetworkFailure(message: 'No network connection available'));
        return;
      }

      yield Right(DiagnosticProgressEntity(
        stage: DiagnosticStage.initializing,
        progress: 0.0,
        message: 'Iniciando diagnóstico...',
        timestamp: DateTime.now(),
      ));
      
      final deviceInfo = await deviceInfoLocalDataSource.getDeviceInfo();
      yield Right(DiagnosticProgressEntity(
        stage: DiagnosticStage.collectingDeviceInfo,
        progress: 1.0,
        message: 'Informações do dispositivo coletadas',
        timestamp: DateTime.now(),
      ));

      final initialNetworkInfo = await networkInfoLocalDataSource.getInitialNetworkInfo();
      yield Right(DiagnosticProgressEntity(
        stage: DiagnosticStage.collectingNetworkInfo,
        progress: 1.0,
        message: 'Informações de rede coletadas',
        timestamp: DateTime.now(),
      ));

      final progressStream = speedTestRemoteDataSource.runSpeedTest();

      await for (final progress in progressStream) {
        yield Right(progress);

        if (progress.stage == DiagnosticStage.completed && progress.speedTestResult != null) {
          final finalNetworkInfo = await networkInfoLocalDataSource.getNetworkInfo();

          final finalResults = FinalResultsModel(
            timestamp: DateTime.now(),
            deviceInfo: DeviceInfoModel.fromEntity(deviceInfo),
            networkInfo: NetworkInfoModel.fromEntity(finalNetworkInfo),
            initialNetworkInfo: NetworkInfoModel.fromEntity(initialNetworkInfo),
            speedTestResult: SpeedTestResultModel.fromEntity(progress.speedTestResult!),
          );

          yield Right(DiagnosticCompleted(finalResults));
          return;
        }
      }

      yield const Left(SpeedTestFailure(message: 'Speed test stream ended unexpectedly.'));

    } on NetworkException catch (e) {
      yield Left(NetworkFailure(message: e.message));
    } on SpeedTestException catch (e) {
      yield Left(SpeedTestFailure(message: e.message));
    } on DeviceInfoException catch (e) {
      yield Left(DeviceInfoFailure(message: e.message));
    } catch (e) {
      yield Left(ServerFailure(message: 'Diagnostic test failed: ${e.toString()}'));
    }
  }

  Future<Either<Failure, T>> _executeDataSourceCall<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on DeviceInfoException catch (e) {
      return Left(DeviceInfoFailure(message: e.message));
    } on SpeedTestException catch (e) {
      return Left(SpeedTestFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, NetworkInfoEntity>> getInitialNetworkInfo() async {
    return _executeDataSourceCall(() async {
      if (!await networkInfo.isConnected) {
        throw const NetworkException('No network connection available');
      }
      return networkInfoLocalDataSource.getInitialNetworkInfo();
    });
  }

  @override
  Future<Either<Failure, DeviceInfoEntity>> getDeviceInfo() async {
    return _executeDataSourceCall(deviceInfoLocalDataSource.getDeviceInfo);
  }

  @override
  Future<Either<Failure, NetworkInfoEntity>> getNetworkInfo() async {
    return _executeDataSourceCall(networkInfoLocalDataSource.getNetworkInfo);
  }

  @override
  Future<Either<Failure, SpeedTestResultEntity>> runSpeedTest() async {
    return _executeDataSourceCall(speedTestRemoteDataSource.getSpeedTestResult);
  }

  @override
  Future<Either<Failure, void>> saveDiagnosticResults(FinalResultsEntity results) async {
    try {
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save results: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<FinalResultsEntity>>> getSavedResults() async {
    try {
      return const Right([]);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get saved results: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> generatePdfReport(FinalResultsEntity results) async {
    try {
      return const Right('/path/to/generated/report.pdf');
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to generate PDF: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkServerReachability() async {
    try {
      final urlString = appConfig.speedTestUrl;
      final uri = Uri.parse(urlString);
      final serverOrigin = '${uri.scheme}://${uri.host}:${uri.port}';

      final response = await http.head(Uri.parse(serverOrigin))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode > 0) { 
        return const Right(true);
      } else {
        return const Right(false);
      }
    } on TimeoutException {
      return const Right(false);
    } on SocketException {
      return const Right(false);
    } catch (e) {
      return const Right(false);
    }
  }

  @override
  void disposeResources() {
    speedTestRemoteDataSource.dispose();
  }
}