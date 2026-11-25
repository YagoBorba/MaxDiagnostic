import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  static const String _defaultLocalUrl =
      'http://localhost:7000/librespeed_runner.html';

  const EnvironmentConfig._({
    required this.speedTestUrl,
    required this.speedTestServerUrl,
  });

  factory EnvironmentConfig({String? speedTestUrl}) {
    final resolvedSpeedTestUrl = speedTestUrl ?? _resolveSpeedTestUrl();
    final resolvedServerUrl = _resolveServerUrl(resolvedSpeedTestUrl);

    return EnvironmentConfig._(
      speedTestUrl: resolvedSpeedTestUrl,
      speedTestServerUrl: resolvedServerUrl,
    );
  }

  final String speedTestUrl;
  final String speedTestServerUrl;

  static String _resolveSpeedTestUrl() {
    final envValue = _readFromDotEnv();
    if (envValue != null && envValue.isNotEmpty) {
      return envValue;
    }

    final fileValue = _readFromFile();
    if (fileValue != null && fileValue.isNotEmpty) {
      return fileValue;
    }

    return _defaultLocalUrl;
  }

  static String? _readFromDotEnv() {
    try {
      if (dotenv.isInitialized) {
        return dotenv.maybeGet('SPEED_TEST_URL')?.trim();
      }
    } catch (_) {}
    return null;
  }

  static String? _readFromFile() {
    try {
      final envFile = File('.env');
      if (envFile.existsSync()) {
        final content = envFile.readAsStringSync();
        final lines = content.split('\n');
        for (final line in lines) {
          if (line.trim().startsWith('SPEED_TEST_URL=')) {
            final value = line.split('=')[1].trim();
            if (value.isNotEmpty) {
              return value;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static String _resolveServerUrl(String speedTestUrl) {
    try {
      final uri = Uri.parse(speedTestUrl);
      final portPart = uri.hasPort ? ':${uri.port}' : '';
      final base = '${uri.scheme}://${uri.host}$portPart';
      return base.replaceAll(RegExp(r'/+$'), '');
    } catch (_) {
      return speedTestUrl;
    }
  }

  static String getSpeedTestUrl() => EnvironmentConfig().speedTestUrl;

  static String getServerUrl() => EnvironmentConfig().speedTestServerUrl;
}
