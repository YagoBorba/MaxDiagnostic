import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';
import 'package:maxt_diagnostic/services/report_service.dart';

FinalResultsEntity _results({String? errorMessage}) {
  final now = DateTime(2025, 11, 18, 14, 30);
  const network = NetworkInfoEntity(
    connectionType: 'wifi',
    wifiName: 'Casa',
    wifiFrequency: '5 GHz',
    wifiSignalStrength: -58,
    wifiLinkSpeed: 433,
    wifiBSSID: 'aa:bb:cc:dd:ee:ff',
    internalIP: '192.168.0.10',
    externalIP: '203.0.113.1',
    isp: 'Test ISP',
    wifiChannel: 36,
    wifiStandard: '802.11ac',
  );
  return FinalResultsEntity(
    timestamp: now,
    deviceInfo: const DeviceInfoEntity(
      deviceModel: 'Pixel 7',
      deviceBrand: 'Google',
      operatingSystem: 'Android',
      osVersion: '15',
    ),
    networkInfo: network,
    initialNetworkInfo: network,
    speedTestResult: SpeedTestResultEntity(
      downloadSpeed: 312.4,
      uploadSpeed: 98.7,
      ping: 12.3,
      jitter: 1.8,
      serverLocation: 'Local server',
      testStartTime: now,
      testEndTime: now.add(const Duration(seconds: 40)),
      testCompleted: errorMessage == null,
      errorMessage: errorMessage,
    ),
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  test('builds a PDF document for a completed test', () async {
    final bytes = await ReportService.buildReport(_results());

    expect(bytes, isNotEmpty);
    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
  });

  test('builds a PDF document when the speed test failed', () async {
    final bytes = await ReportService.buildReport(
      _results(errorMessage: 'Servidor indisponível'),
    );

    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
  });
}
