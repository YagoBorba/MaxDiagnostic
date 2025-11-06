import 'dart:io';

class EnvironmentConfig {
  static const String _defaultLocalUrl = 'http://localhost:7000/librespeed_runner.html';
  
  static String getSpeedTestUrl() {
    try {
      final envFile = File('.env');
      if (envFile.existsSync()) {
        final content = envFile.readAsStringSync();
        final lines = content.split('\n');
        for (final line in lines) {
          if (line.trim().startsWith('SPEED_TEST_URL=')) {
            return line.split('=')[1].trim();
          }
        }
      }
    } catch (e) {
      // Ignora erro e usa fallback
    }
    
    return _defaultLocalUrl;
  }
  
  static String getServerUrl() {
    final fullUrl = getSpeedTestUrl();
    final uri = Uri.parse(fullUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }
}
