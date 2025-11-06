import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/final_results_entity.dart';
import '../entities/diagnostic_flow.dart';

abstract class DiagnosticRepository {
  Future<Either<Failure, NetworkInfoEntity>> getInitialNetworkInfo();

  Stream<Either<Failure, DiagnosticFlowEvent>> runDiagnosticTest();

  Future<Either<Failure, DeviceInfoEntity>> getDeviceInfo();
  Future<Either<Failure, NetworkInfoEntity>> getNetworkInfo();

  Future<Either<Failure, SpeedTestResultEntity>> runSpeedTest();

  Future<Either<Failure, void>> saveDiagnosticResults(
      FinalResultsEntity results);

  Future<Either<Failure, List<FinalResultsEntity>>> getSavedResults();

  Future<Either<Failure, String>> generatePdfReport(FinalResultsEntity results);

  void disposeResources();
}
