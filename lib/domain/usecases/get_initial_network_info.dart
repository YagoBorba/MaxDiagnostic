import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/final_results_entity.dart';
import '../repositories/diagnostic_repository.dart';

class GetInitialNetworkInfo implements UseCase<NetworkInfoEntity, NoParams> {
  final DiagnosticRepository repository;

  GetInitialNetworkInfo(this.repository);

  @override
  Future<Either<Failure, NetworkInfoEntity>> call(NoParams params) {
    return repository.getInitialNetworkInfo();
  }
}
