import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:maxt_diagnostic/core/config/app_config.dart';
import 'package:maxt_diagnostic/core/error/exceptions.dart';
import 'package:maxt_diagnostic/core/error/failures.dart';
import 'package:maxt_diagnostic/core/network/network_info.dart';
import 'package:maxt_diagnostic/data/datasources/device_info_local_datasource.dart';
import 'package:maxt_diagnostic/data/datasources/network_info_local_datasource.dart';
import 'package:maxt_diagnostic/data/datasources/speed_test_remote_datasource.dart';
import 'package:maxt_diagnostic/data/datasources/server_capacity_remote_datasource.dart';
import 'package:maxt_diagnostic/data/models/final_results_model.dart';
import 'package:maxt_diagnostic/data/models/server_capacity_model.dart';
import 'package:maxt_diagnostic/data/repositories/diagnostic_repository_impl.dart';
import 'package:maxt_diagnostic/domain/entities/diagnostic_flow.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';

class _MockNetworkInfoLocalDataSource extends Mock
    implements NetworkInfoLocalDataSource {}

class _MockSpeedTestRemoteDataSource extends Mock
    implements SpeedTestRemoteDataSource {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

class _MockAppConfig extends Mock implements AppConfig {}

class _MockDeviceInfoLocalDataSource extends Mock
    implements DeviceInfoLocalDataSource {}

class _MockServerCapacityRemoteDataSource extends Mock
    implements ServerCapacityRemoteDataSource {}

void main() {
  late _MockNetworkInfoLocalDataSource networkInfoLocalDataSource;
  late _MockSpeedTestRemoteDataSource speedTestRemoteDataSource;
  late _MockNetworkInfo networkInfo;
  late _MockDeviceInfoLocalDataSource deviceInfoLocalDataSource;
  late _MockServerCapacityRemoteDataSource serverCapacityRemoteDataSource;
  late _MockAppConfig appConfig;
  late DiagnosticRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue('stub-client-id');
  });

  setUp(() {
    networkInfoLocalDataSource = _MockNetworkInfoLocalDataSource();
    speedTestRemoteDataSource = _MockSpeedTestRemoteDataSource();
    networkInfo = _MockNetworkInfo();
    deviceInfoLocalDataSource = _MockDeviceInfoLocalDataSource();
    serverCapacityRemoteDataSource = _MockServerCapacityRemoteDataSource();
    appConfig = _MockAppConfig();

    repository = DiagnosticRepositoryImpl(
      networkInfoLocalDataSource: networkInfoLocalDataSource,
      speedTestRemoteDataSource: speedTestRemoteDataSource,
      networkInfo: networkInfo,
      deviceInfoLocalDataSource: deviceInfoLocalDataSource,
      serverCapacityRemoteDataSource: serverCapacityRemoteDataSource,
      appConfig: appConfig,
    );
  });

  group('runDiagnosticTest', () {
    test('emits DiagnosticQueueing when server is busy', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => deviceInfoLocalDataSource.getDeviceInfo()).thenAnswer(
        (_) async => const DeviceInfoEntity(
          deviceModel: 'Pixel 7',
          deviceBrand: 'Google',
          operatingSystem: 'Android',
          osVersion: '14',
        ),
      );
      when(() => networkInfoLocalDataSource.getInitialNetworkInfo())
          .thenAnswer((_) async => const NetworkInfoEntity(connectionType: 'WiFi'));

      when(() => serverCapacityRemoteDataSource.reserveSlot(any())).thenAnswer(
        (_) async => const ServerCapacityModel(
          status: 'BUSY',
          estimatedWaitSeconds: 12,
        ),
      );

      final events = await repository.runDiagnosticTest().toList();

      expect(events.every((element) => element.isRight()), isTrue);
      final lastEvent = events.last;
      lastEvent.fold(
        (_) => fail('Expected DiagnosticQueueing event as the final emission'),
        (event) {
          expect(event, isA<DiagnosticQueueing>());
          final queueEvent = event as DiagnosticQueueing;
          expect(queueEvent.estimatedWaitSeconds, 12);
        },
      );

      verifyNever(() => serverCapacityRemoteDataSource.releaseSlot(any()));
      verifyNever(() => speedTestRemoteDataSource.runSpeedTest());
    });

    test('emits progress updates and final results on completion', () async {
      // Arrange
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => serverCapacityRemoteDataSource.reserveSlot(any())).thenAnswer(
        (_) async => const ServerCapacityModel(status: 'GRANTED', token: 'token'),
      );
      when(() => serverCapacityRemoteDataSource.releaseSlot(any())).thenAnswer((_) async {});

      const device = DeviceInfoEntity(
        deviceModel: 'Pixel 7',
        deviceBrand: 'Google',
        operatingSystem: 'Android',
        osVersion: '14',
      );
      when(() => deviceInfoLocalDataSource.getDeviceInfo())
          .thenAnswer((_) async => device);

    const netInitial = NetworkInfoEntity(
        connectionType: 'WiFi',
        wifiName: 'MyWiFi',
        wifiFrequency: '5 GHz',
        wifiSignalStrength: -50,
        wifiLinkSpeed: 300,
      );
    const netFinal = NetworkInfoEntity(
        connectionType: 'WiFi',
        wifiName: 'MyWiFi',
        wifiFrequency: '5 GHz',
        wifiSignalStrength: -45,
        wifiLinkSpeed: 433,
      );
      when(() => networkInfoLocalDataSource.getInitialNetworkInfo())
          .thenAnswer((_) async => netInitial);
      when(() => networkInfoLocalDataSource.getNetworkInfo())
          .thenAnswer((_) async => netFinal);

      final speedResult = SpeedTestResultModel(
        downloadSpeed: 100.0,
        uploadSpeed: 50.0,
        ping: 12.0,
        jitter: 3.0,
        serverLocation: 'São Paulo - BR',
        testStartTime: DateTime.now().subtract(const Duration(seconds: 30)),
        testEndTime: DateTime.now(),
        testCompleted: true,
      );
      when(() => speedTestRemoteDataSource.getSpeedTestResult())
          .thenAnswer((_) async => speedResult);

      final controller = StreamController<DiagnosticProgressEntity>();
      when(() => speedTestRemoteDataSource.runSpeedTest())
          .thenAnswer((_) => controller.stream);

      // Act
      final emitted = <Either<Failure, DiagnosticFlowEvent>>[];
      final sub = repository.runDiagnosticTest().listen(emitted.add);

      controller.add(DiagnosticProgressEntity(
        stage: DiagnosticStage.runningDownloadTest,
        progress: 0.5,
        message: 'Downloading...',
        timestamp: DateTime.now(),
      ));
      controller.add(DiagnosticProgressEntity(
        stage: DiagnosticStage.completed,
        progress: 1.0,
        message: 'Done',
        timestamp: DateTime.now(),
        speedTestResult: speedResult,
      ));
      
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await controller.close(); 
      await sub.cancel();

      // Assert
      expect(emitted.isNotEmpty, true);

      final rights = emitted.where((e) => e.isRight());
      expect(rights.isNotEmpty, true);

      final completedEvents = rights
          .map((e) => e.getOrElse(() => throw ''))
          .whereType<DiagnosticCompleted>()
          .toList();
      expect(completedEvents.length, 1);
      final finalResults = completedEvents.first.results;
      expect(finalResults.deviceInfo.deviceModel, device.deviceModel);
      expect(finalResults.networkInfo.wifiLinkSpeed, netFinal.wifiLinkSpeed);
      expect(finalResults.speedTestResult.downloadSpeed, speedResult.downloadSpeed);
    });

    test('emits NetworkFailure when not connected', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);
      when(() => serverCapacityRemoteDataSource.reserveSlot(any())).thenAnswer(
        (_) async => const ServerCapacityModel(status: 'GRANTED', token: 'token'),
      );
      when(() => serverCapacityRemoteDataSource.releaseSlot(any())).thenAnswer((_) async {});

      final first = await repository.runDiagnosticTest().first;

      expect(
        first.fold((l) => l, (r) => null),
        isA<NetworkFailure>(),
      );
    });

    test('emits SpeedTestFailure when getSpeedTestResult throws after completion',
        () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => deviceInfoLocalDataSource.getDeviceInfo())
          .thenAnswer((_) async => const DeviceInfoEntity(
                deviceModel: 'Any',
                deviceBrand: 'Any',
                operatingSystem: 'Android',
                osVersion: '14',
              ));
      when(() => serverCapacityRemoteDataSource.reserveSlot(any())).thenAnswer(
        (_) async => const ServerCapacityModel(status: 'GRANTED', token: 'token'),
      );
      when(() => serverCapacityRemoteDataSource.releaseSlot(any())).thenAnswer((_) async {});
    when(() => networkInfoLocalDataSource.getInitialNetworkInfo())
      .thenAnswer((_) async => const NetworkInfoEntity(connectionType: 'WiFi'));
    when(() => networkInfoLocalDataSource.getNetworkInfo())
      .thenAnswer((_) async => const NetworkInfoEntity(connectionType: 'WiFi'));

      final controller = StreamController<DiagnosticProgressEntity>();
      when(() => speedTestRemoteDataSource.runSpeedTest())
          .thenAnswer((_) => controller.stream);
      when(() => speedTestRemoteDataSource.getSpeedTestResult())
          .thenThrow(const SpeedTestException('boom'));

      final stream = repository.runDiagnosticTest();
      Future.microtask(() {
        controller.add(DiagnosticProgressEntity(
          stage: DiagnosticStage.completed,
          progress: 1,
          message: 'Done',
          timestamp: DateTime.now(),
          speedTestResult: SpeedTestResultEntity(
            downloadSpeed: 100.0,
            uploadSpeed: 50.0,
            ping: 12.0,
            jitter: 3.0,
            serverLocation: 'Servidor Interno',
            testStartTime: DateTime.now(),
            testEndTime: DateTime.now(),
            testCompleted: true,
          ),
        ));
        controller.close();
      });

      final firstLeft = await stream.firstWhere((e) => e.isLeft(), orElse: () => const Left(SpeedTestFailure(message: 'Test failure')));
      expect(firstLeft.swap().getOrElse(() => throw ''), isA<SpeedTestFailure>());
    });
  });
}
