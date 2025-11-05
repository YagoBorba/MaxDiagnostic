class ServerException implements Exception {
  final String message;

  const ServerException(this.message);
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
