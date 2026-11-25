class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException(this.message, {this.statusCode});

  @override
  String toString() =>
      'ServerException(statusCode: $statusCode, message: $message)';
}

class CacheException implements Exception {
  final String message;

  const CacheException(this.message);
}

class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);
}

class DeviceInfoException implements Exception {
  final String message;

  const DeviceInfoException(this.message);
}

class SpeedTestException implements Exception {
  final String message;

  const SpeedTestException(this.message);
}

class PermissionException implements Exception {
  final String message;

  const PermissionException(this.message);
}

class ServerBusyException implements Exception {
  final String message;
  final int estimatedWaitSeconds;

  const ServerBusyException(
    this.message, {
    this.estimatedWaitSeconds = 30,
  });

  @override
  String toString() =>
      'ServerBusyException(estimatedWaitSeconds: $estimatedWaitSeconds, message: $message)';
}
