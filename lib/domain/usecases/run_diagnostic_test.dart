import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/final_results_entity.dart';
import '../repositories/diagnostic_repository.dart';

/// Use case for running the complete diagnostic test
/// This orchestrates the entire diagnostic process and emits progress updates
class RunDiagnosticTest implements UseCase<Stream<Either<Failure, DiagnosticProgressEntity>>, NoParams> {
  final DiagnosticRepository repository;

  RunDiagnosticTest(this.repository);

  @override
  Future<Either<Failure, Stream<Either<Failure, DiagnosticProgressEntity>>>> call(NoParams params) async {
    try {
      final stream = repository.runDiagnosticTest();
      return Right(stream);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
