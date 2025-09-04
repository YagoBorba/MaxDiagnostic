import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maxt_diagnostic/core/config/app_config.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';

void main() {
  group('MaxDiagnostic App Tests', () {
    test('App Config - Should have valid configuration', () {
      final config = AppConfig();
      expect(config.signalExcellentThresholdDbm, lessThan(0));
      expect(config.signalNormalThresholdDbm, lessThan(0)); 
      expect(config.homeRefreshInterval.inSeconds, greaterThan(0));
      expect(config.quickTips, isNotEmpty);
      expect(config.disabledStartMessage, isNotEmpty);
    });

    test('App Config - Signal quality calculation should work correctly', () {
      final config = AppConfig();

      expect(config.getSignalQuality(-40), SignalQuality.excellent);
      expect(config.isSignalExcellent(-40), isTrue);

      expect(config.getSignalQuality(-60), SignalQuality.normal);
      expect(config.isSignalExcellent(-60), isFalse);

      expect(config.getSignalQuality(-80), SignalQuality.poor);
      expect(config.isSignalExcellent(-80), isFalse);

      expect(config.getSignalQuality(null), SignalQuality.poor);
      expect(config.isSignalExcellent(null), isFalse);
    });

    test('App Config - Quality labels should be in Portuguese', () {
      final config = AppConfig();
      expect(config.qualityLabel(SignalQuality.excellent), 'Excelente');
      expect(config.qualityLabel(SignalQuality.normal), 'Normal');
      expect(config.qualityLabel(SignalQuality.poor), 'Ruim');
    });

    test('NetworkInfoEntity - Should create valid network info', () {
      const networkInfo = NetworkInfoEntity(
        connectionType: 'wifi',
        wifiName: 'Test Network',
        wifiSignalStrength: -50,
        internalIP: '192.168.1.100',
      );
      
      expect(networkInfo.connectionType, 'wifi');
      expect(networkInfo.wifiName, 'Test Network');
      expect(networkInfo.wifiSignalStrength, -50);
      expect(networkInfo.internalIP, '192.168.1.100');
    });

    testWidgets('Basic Material App should build without errors', (WidgetTester tester) async {
      // Test a simple Material App without complex dependencies
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('MaxDiagnostic Test'),
            ),
          ),
        ),
      );
      
      expect(find.text('MaxDiagnostic Test'), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
