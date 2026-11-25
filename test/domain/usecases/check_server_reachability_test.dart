import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maxt_diagnostic/core/usecases/usecase.dart';
import 'package:maxt_diagnostic/domain/repositories/diagnostic_repository.dart';
import 'package:maxt_diagnostic/domain/usecases/check_server_reachability.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements DiagnosticRepository {}

void main() {
  late _MockRepository repository;

  setUp(() => repository = _MockRepository());

  test('asks the repository whether the speed test server answers', () async {
    when(() => repository.checkServerReachability())
        .thenAnswer((_) async => const Right(false));

    final result = await CheckServerReachability(repository)(const NoParams());

    expect(result, const Right(false));
    verify(() => repository.checkServerReachability()).called(1);
  });

  test('demo mode reports the server as reachable without calling it', () async {
    final result = await DemoServerReachability(repository)(const NoParams());

    expect(result, const Right(true));
    verifyNever(() => repository.checkServerReachability());
  });
}
