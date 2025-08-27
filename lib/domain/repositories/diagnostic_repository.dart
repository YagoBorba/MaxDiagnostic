import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/final_results_entity.dart';
import '../entities/diagnostic_flow.dart';

/// Repository contract for diagnostic operations
/// This defines what operations are available without specifying how they work
abstract class DiagnosticRepository {
  /// Get initial network information to display on home screen
  Future<Either<Failure, NetworkInfoEntity>> getInitialNetworkInfo();

  /// Run the complete diagnostic test
  /// Returns a stream of progress updates followed by a final results event
  Stream<Either<Failure, DiagnosticFlowEvent>> runDiagnosticTest();

  /// Get device information
  Future<Either<Failure, DeviceInfoEntity>> getDeviceInfo();

  /// Get detailed network information
  Future<Either<Failure, NetworkInfoEntity>> getNetworkInfo();

  /// Run speed test and return results
  Future<Either<Failure, SpeedTestResultEntity>> runSpeedTest();

  /// Save diagnostic results locally
  Future<Either<Failure, void>> saveDiagnosticResults(
      FinalResultsEntity results);

  /// Get saved diagnostic results
  Future<Either<Failure, List<FinalResultsEntity>>> getSavedResults();

  /// Generate PDF report from results
  Future<Either<Failure, String>> generatePdfReport(FinalResultsEntity results);
}
