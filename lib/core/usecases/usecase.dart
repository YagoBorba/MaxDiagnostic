import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// Base use case interface for all use cases in the application
/// Type = the type of object returned by the use case
/// Params = the type of parameter received by the use case
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case for when no parameters are needed
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
