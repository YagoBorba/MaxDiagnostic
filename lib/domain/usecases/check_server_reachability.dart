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
