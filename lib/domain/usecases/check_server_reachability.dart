import 'package:dartz/dartz.dart';
import 'package:maxt_diagnostic/core/error/failures.dart';
import 'package:maxt_diagnostic/core/usecases/usecase.dart';
import 'package:maxt_diagnostic/domain/repositories/diagnostic_repository.dart';

class CheckServerReachability implements UseCase<bool, NoParams> {
  final DiagnosticRepository repository;

  CheckServerReachability(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return repository.checkServerReachability();
  }
}

/// Used in demo mode: the diagnostic is simulated, so no server is needed.
class DemoServerReachability extends CheckServerReachability {
  DemoServerReachability(super.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async =>
      const Right(true);
}
