import 'dart:async';

import 'dart:convert';

import 'package:dart_ping/dart_ping.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:maxt_diagnostic/core/error/exceptions.dart';
import 'package:maxt_diagnostic/data/datasources/ping_remote_datasource.dart';
import 'package:maxt_diagnostic/domain/entities/diagnostic_flow.dart';

class _TestPing implements Ping {
  _TestPing(this._stream, {Future<bool> Function()? onStop}) : _onStop = onStop;

  final Stream<PingData> _stream;
  final Future<bool> Function()? _onStop;

  @override
  String get command => 'ping test';

  @override
  late PingParser parser = PingParser(
    responseRgx: RegExp(''),
    summaryRgx: RegExp(''),
    timeoutRgx: RegExp(''),
    timeToLiveRgx: RegExp(''),
    unknownHostStr: RegExp(''),
  );

  @override
  Stream<PingData> get stream => _stream;

  @override
  Future<bool> stop() async => _onStop?.call() ?? true;
}

class _TestClock {
  _TestClock(DateTime seed) : _current = seed;

  DateTime _current;

  DateTime call() {
    final now = _current;
    _current = _current.add(const Duration(milliseconds: 200));
    return now;
  }
}

void main() {
  late StreamController<PingData> controller;
  late _TestClock clock;
  late PingRemoteDataSourceImpl dataSource;

  setUp(() {
    controller = StreamController<PingData>();
    clock = _TestClock(DateTime(2025, 1, 1));
    dataSource = PingRemoteDataSourceImpl(
      host: 'example.com',
      count: 4,
      intervalSeconds: 1,
      timeoutSeconds: 2,
      pingCreator: (
        host, {
        int? count,
        int interval = 1,
        int timeout = 2,
        int ttl = 255,
        bool ipv6 = false,
        PingParser? parser,
        Encoding encoding = const Utf8Codec(),
        bool forceCodepage = false,
      }) {
        return _TestPing(controller.stream);
      },
      now: () => clock(),
    );
  });

  tearDown(() async {
    await controller.close();
    await dataSource.dispose();
  });

  test('emits progress and final ping result', () async {
  final events = <DiagnosticProgressEntity>[];
  final subscription = dataSource.runPingTest().listen(events.add);

  controller.add(const PingData(response: PingResponse(seq: 0, time: Duration(milliseconds: 20))));
  controller.add(const PingData(response: PingResponse(seq: 1, time: Duration(milliseconds: 22))));
  controller.add(const PingData(error: PingError(ErrorType.requestTimedOut)));
  controller.add(PingData(summary: PingSummary(transmitted: 3, received: 2)));
  await controller.close();
  await Future<void>.delayed(const Duration(milliseconds: 10));
  await subscription.cancel();

  expect(events, isNotEmpty);

  final summaryEvent = events.lastWhere((event) => event.pingResult != null);
  expect(summaryEvent.pingResult, isNotNull);
    final result = summaryEvent.pingResult!;
    expect(result.transmitted, 3);
    expect(result.received, 2);
    expect(result.averageLatencyMs, closeTo(21.0, 0.001));
    expect(result.packetLossPercentage, closeTo(33.333, 0.01));

    final resolved = await dataSource.getPingResult();
    expect(resolved.averageLatencyMs, result.averageLatencyMs);
  });

  test('throws PingException when summary not produced', () async {
    final events = <DiagnosticProgressEntity>[];
    final subscription = dataSource
        .runPingTest()
        .handleError((_, __) {})
        .listen(events.add);

  final future = dataSource.getPingResult();
  final errorExpectation = expectLater(future, throwsA(isA<PingException>()));
    controller.add(const PingData(error: PingError(ErrorType.unknownHost)));
    await controller.close();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    try {
      await subscription.cancel();
    } catch (_) {}

    expect(
      events.where((event) => event.message.contains('Host de ping desconhecido')),
      isNotEmpty,
    );
  expect(events.last.message, contains('Resumo de ping não foi produzido'));
  await errorExpectation;
  });

  test('dispose prevents reuse', () async {
    dataSource.runPingTest();
    await dataSource.dispose();

    expect(() => dataSource.runPingTest(), throwsA(isA<PingException>()));
  });
}
