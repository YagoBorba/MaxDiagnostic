import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/diagnostic_flow.dart';
import '../repositories/diagnostic_repository.dart';

class RunDiagnosticTest
    implements UseCase<Stream<Either<Failure, DiagnosticFlowEvent>>, NoParams> {
  final DiagnosticRepository? repository;
  final UseCase<Stream<Either<Failure, DiagnosticFlowEvent>>, NoParams>? _mockImplementation;

  RunDiagnosticTest(this.repository) : _mockImplementation = null;
  
  RunDiagnosticTest.mock(this._mockImplementation) : repository = null;

  @override
  Future<Either<Failure, Stream<Either<Failure, DiagnosticFlowEvent>>>> call(
      NoParams params) async {
    try {
      if (_mockImplementation != null) {
        return await _mockImplementation.call(params);
      }
      
      if (repository == null) {
        return const Left(ServerFailure('Repository not initialized'));
      }
      
      final stream = repository!.runDiagnosticTest();
      return Right(stream);
    } catch (e) {
      return Left(ServerFailure('Failed to start diagnostic: ${e.toString()}'));
    }
  }
}

