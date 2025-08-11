import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
/// Following clean architecture principles
abstract class Failure extends Equatable {
  const Failure([List properties = const <dynamic>[]]);

  @override
  List<Object> get props => [];
}

/// General failures
class ServerFailure extends Failure {
  final String message;

  const ServerFailure(this.message);

  @override
  List<Object> get props => [message];
}

class CacheFailure extends Failure {
  final String message;

  const CacheFailure(this.message);

  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  final String message;

  const NetworkFailure(this.message);

  @override
  List<Object> get props => [message];
}

class DeviceInfoFailure extends Failure {
  final String message;

  const DeviceInfoFailure(this.message);

  @override
  List<Object> get props => [message];
}

class SpeedTestFailure extends Failure {
  final String message;

  const SpeedTestFailure(this.message);

  @override
  List<Object> get props => [message];
}

class PermissionFailure extends Failure {
  final String message;

  const PermissionFailure(this.message);

  @override
  List<Object> get props => [message];
}
