import 'package:dartz/dartz.dart';
import 'package:maxt_diagnostic/core/di/error/failures.dart';
import 'package:maxt_diagnostic/domain/entities/diagnostic_result.dart';
import 'package:maxt_diagnostic/domain/repositories/diagnostic_repository.dart';

// Este é o caso de uso para executar um teste de velocidade.
class ExecuteSpeedTest {
  final IDiagnosticRepository repository;

  ExecuteSpeedTest(this.repository);

  // A interface "callable" do caso de uso.
  Future<Either<Failure, DiagnosticResult>> call() async {
    return await repository.performSpeedTest();
  }
}