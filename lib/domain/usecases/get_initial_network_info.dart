import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/final_results_entity.dart';
import '../repositories/diagnostic_repository.dart';

/// Use case for getting initial network information
/// This is called when the home screen loads to show current network status
class GetInitialNetworkInfo implements UseCase<NetworkInfoEntity, NoParams> {
  final DiagnosticRepository repository;

  GetInitialNetworkInfo(this.repository);

  @override
  Future<Either<Failure, NetworkInfoEntity>> call(NoParams params) async {
    return await repository.getInitialNetworkInfo();
  }
}
