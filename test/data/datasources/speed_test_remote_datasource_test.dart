import 'dart:async';

import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';
import 'package:flutter_internet_speed_test/src/flutter_internet_speed_test_platform_interface.dart'
  as fist;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:maxt_diagnostic/core/config/app_config.dart';
import 'package:maxt_diagnostic/core/error/exceptions.dart';
import 'package:maxt_diagnostic/data/datasources/speed_test_remote_datasource.dart';
import 'package:maxt_diagnostic/domain/entities/diagnostic_flow.dart';

class _MockSpeedTestClient extends Mock implements SpeedTestClient {}

class _TestClock {
  _TestClock(DateTime initial) : _current = initial;

  DateTime _current;

  DateTime call() {
    final now = _current;
    _current = _current.add(const Duration(milliseconds: 250));
    return now;
  }
}

void main() {
  late _MockSpeedTestClient mockClient;
  late SpeedTestRemoteDataSourceImpl dataSource;
  late _TestClock clock;
  late AppConfig config;

  setUp(() {
    mockClient = _MockSpeedTestClient();
    clock = _TestClock(DateTime(2025, 1, 1));
    config = AppConfig(
      speedTestUrl: 'https://speedtest.example.com',
      speedTestDownloadUrl: 'https://download.example.com/file',
      speedTestUploadUrl: 'https://upload.example.com/',
      speedTestFileSizeBytes: 200000,
    );
    dataSource = SpeedTestRemoteDataSourceImpl(
      config: config,
      speedTestClient: mockClient,
      now: () => clock(),
    );
  });

  group('runSpeedTest', () {
    test('emits download, upload and completion events with final result', () async {
      when(() => mockClient.startDownloadTesting(
            onDone: any(named: 'onDone'),
            onProgress: any(named: 'onProgress'),
            onError: any(named: 'onError'),
            fileSize: any(named: 'fileSize'),
            testServer: any(named: 'testServer'),
          )).thenAnswer((invocation) {
        final onProgress =
            invocation.namedArguments[const Symbol('onProgress')] as fist.ProgressCallback;
        final onDone =
            invocation.namedArguments[const Symbol('onDone')] as fist.DoneCallback;

        onProgress(45, 42000, SpeedUnit.Kbps);
        onDone(82000, SpeedUnit.Kbps);
        return Future.value(() {});
      });

      when(() => mockClient.startUploadTesting(
            onDone: any(named: 'onDone'),
            onProgress: any(named: 'onProgress'),
            onError: any(named: 'onError'),
            fileSize: any(named: 'fileSize'),
            testServer: any(named: 'testServer'),
          )).thenAnswer((invocation) {
        final onProgress =
            invocation.namedArguments[const Symbol('onProgress')] as fist.ProgressCallback;
        final onDone =
            invocation.namedArguments[const Symbol('onDone')] as fist.DoneCallback;

        onProgress(55, 23000, SpeedUnit.Kbps);
        onDone(35000, SpeedUnit.Kbps);
        return Future.value(() {});
      });

      final stream = dataSource.runSpeedTest();
      final events = await stream.toList();

      expect(events.first.stage, DiagnosticStage.startingSpeedTest);
      expect(events.last.stage, DiagnosticStage.completed);
      expect(
        events.where((event) => event.stage == DiagnosticStage.runningDownloadTest),
        isNotEmpty,
      );
      expect(
        events.where((event) => event.stage == DiagnosticStage.runningUploadTest),
        isNotEmpty,
      );

      final completedEvent = events.last;
      expect(completedEvent.speedTestResult, isNotNull);
      expect(completedEvent.speedTestResult!.downloadSpeed, closeTo(82, 0.001));
      expect(completedEvent.speedTestResult!.uploadSpeed, closeTo(35, 0.001));

      final result = await dataSource.getSpeedTestResult();
      expect(result.downloadSpeed, closeTo(82, 0.001));
      expect(result.uploadSpeed, closeTo(35, 0.001));
      expect(result.testCompleted, isTrue);
      expect(result.serverLocation, config.speedTestUrl);
    });

    test('emits error and completes with SpeedTestException when download fails', () async {
      when(() => mockClient.startDownloadTesting(
            onDone: any(named: 'onDone'),
            onProgress: any(named: 'onProgress'),
            onError: any(named: 'onError'),
            fileSize: any(named: 'fileSize'),
            testServer: any(named: 'testServer'),
          )).thenAnswer((invocation) {
        final onError =
            invocation.namedArguments[const Symbol('onError')] as fist.ErrorCallback;
        onError('Falha ao iniciar download', 'timeout');
        return Future.value(() {});
      });

      final stream = dataSource.runSpeedTest();
      final events = await stream.toList();

      expect(events.first.stage, DiagnosticStage.startingSpeedTest);
      expect(events.last.stage, DiagnosticStage.error);
      expect(events.last.message, contains('Falha ao iniciar download'));

      final resultFuture = dataSource.getSpeedTestResult();
      expect(resultFuture, throwsA(isA<SpeedTestException>()));
    });

    test('emits error when upload fails after download', () async {
      when(() => mockClient.startDownloadTesting(
            onDone: any(named: 'onDone'),
            onProgress: any(named: 'onProgress'),
            onError: any(named: 'onError'),
            fileSize: any(named: 'fileSize'),
            testServer: any(named: 'testServer'),
          )).thenAnswer((invocation) {
        final onDone =
            invocation.namedArguments[const Symbol('onDone')] as fist.DoneCallback;
        onDone(75000, SpeedUnit.Kbps);
        return Future.value(() {});
      });

      when(() => mockClient.startUploadTesting(
            onDone: any(named: 'onDone'),
            onProgress: any(named: 'onProgress'),
            onError: any(named: 'onError'),
            fileSize: any(named: 'fileSize'),
            testServer: any(named: 'testServer'),
          )).thenAnswer((invocation) {
        final onError =
            invocation.namedArguments[const Symbol('onError')] as fist.ErrorCallback;
        onError('Falha no upload', 'connection-lost');
        return Future.value(() {});
      });

      final stream = dataSource.runSpeedTest();
      final events = await stream.toList();

      expect(events.last.stage, DiagnosticStage.error);
      expect(events.last.message, contains('Falha no upload'));
      final resultFuture = dataSource.getSpeedTestResult();
      expect(resultFuture, throwsA(isA<SpeedTestException>()));
    });
  });

  test('dispose impede novas execuções após cancelamento', () async {
    final downloadCompleter = Completer<void>();
    when(() => mockClient.startDownloadTesting(
          onDone: any(named: 'onDone'),
          onProgress: any(named: 'onProgress'),
          onError: any(named: 'onError'),
          fileSize: any(named: 'fileSize'),
          testServer: any(named: 'testServer'),
        )).thenAnswer((_) {
      downloadCompleter.complete();
      return Future.value(() {});
    });

    dataSource.runSpeedTest();
    await downloadCompleter.future;

    dataSource.dispose();

    expect(
      () => dataSource.runSpeedTest(),
      throwsA(isA<SpeedTestException>()),
    );
  });
}
