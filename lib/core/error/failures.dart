import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});
  
  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

class DeviceInfoFailure extends Failure {
  const DeviceInfoFailure({required super.message});
}

class SpeedTestFailure extends Failure {
  const SpeedTestFailure({required super.message});
}

class PermissionFailure extends Failure {
  const PermissionFailure({required super.message});
}