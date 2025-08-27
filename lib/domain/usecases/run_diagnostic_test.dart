import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/diagnostic_flow.dart';
import '../repositories/diagnostic_repository.dart';

/// Stream use case to run diagnostic test and emit progress and final results
class RunDiagnosticTest
		implements UseCase<Stream<Either<Failure, DiagnosticFlowEvent>>, NoParams> {
	final DiagnosticRepository repository;

	RunDiagnosticTest(this.repository);

	@override
	Future<Either<Failure, Stream<Either<Failure, DiagnosticFlowEvent>>>> call(
			NoParams params) async {
		try {
			final stream = repository.runDiagnosticTest();
			return Right(stream);
		} catch (e) {
			return Left(ServerFailure('Failed to start diagnostic: ${e.toString()}'));
		}
	}
}

