import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:maxt_diagnostic/core/error/failures.dart';
import 'package:maxt_diagnostic/core/usecases/usecase.dart';
import 'package:maxt_diagnostic/domain/entities/diagnostic_flow.dart';
import 'package:maxt_diagnostic/domain/repositories/diagnostic_repository.dart';
import 'package:maxt_diagnostic/domain/usecases/run_diagnostic_test.dart';

class _MockRepository extends Mock implements DiagnosticRepository {}

void main() {
  late _MockRepository repository;
  late RunDiagnosticTest usecase;

  setUp(() {
    repository = _MockRepository();
    usecase = RunDiagnosticTest(repository);
  });

  test('returns repository stream on success', () async {
    final controller = StreamController<Either<Failure, DiagnosticFlowEvent>>();
    when(() => repository.runDiagnosticTest()).thenAnswer((_) => controller.stream);

    final result = await usecase(const NoParams());

    expect(result.isRight(), true);
    final stream = result.getOrElse(() => throw '');
    expect(stream, isA<Stream<Either<Failure, DiagnosticFlowEvent>>>());
  });

  test('propagates failure when repository throws sync', () async {
    when(() => repository.runDiagnosticTest()).thenThrow(Exception('bad'));

    final result = await usecase(const NoParams());

    expect(result.isLeft(), true);
    expect(result.swap().getOrElse(() => throw ''), isA<ServerFailure>());
  });
}
