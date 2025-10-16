import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_ping/dart_ping.dart';

import '../../core/error/exceptions.dart';
import '../../domain/entities/diagnostic_flow.dart';
import '../models/ping_result_model.dart';

typedef PingCreator = Ping Function(
  String host, {
  int? count,
  int interval,
  int timeout,
  int ttl,
  bool ipv6,
  PingParser? parser,
  Encoding encoding,
  bool forceCodepage,
});

abstract class PingRemoteDataSource {
  Stream<DiagnosticProgressEntity> runPingTest();
  Future<PingResultModel> getPingResult();
  Future<void> dispose();
}

class PingRemoteDataSourceImpl implements PingRemoteDataSource {
  PingRemoteDataSourceImpl({
    this.host = '8.8.8.8',
    this.count = 6,
    this.intervalSeconds = 1,
    this.timeoutSeconds = 2,
    this.ttl = 64,
    this.ipv6 = false,
    this.forceCodepageOnWindows = true,
    PingCreator? pingCreator,
    DateTime Function()? now,
  })  : _pingCreator = pingCreator ?? _defaultPingCreator,
        _now = now ?? DateTime.now;

  final String host;
  final int count;
  final int intervalSeconds;
  final int timeoutSeconds;
  final int ttl;
  final bool ipv6;
  final bool forceCodepageOnWindows;
  final PingCreator _pingCreator;
  final DateTime Function() _now;

  StreamController<DiagnosticProgressEntity>? _progressController;
  Completer<PingResultModel>? _resultCompleter;
  PingResultModel? _latestResult;
  PingException? _pendingException;
  StreamSubscription<PingData>? _subscription;
  Ping? _activePing;
  bool _isDisposed = false;
  bool _isRunning = false;

  static Ping _defaultPingCreator(
    String host, {
    int? count,
    int interval = 1,
    int timeout = 2,
    int ttl = 255,
    bool ipv6 = false,
    PingParser? parser,
    Encoding encoding = const Utf8Codec(),
    bool forceCodepage = false,
  }) {
    return Ping(
      host,
      count: count,
      interval: interval,
      timeout: timeout,
      ttl: ttl,
      ipv6: ipv6,
      parser: parser,
      encoding: encoding,
      forceCodepage: forceCodepage,
    );
  }

  @override
  Stream<DiagnosticProgressEntity> runPingTest() {
    if (_isDisposed) {
      throw const PingException('Ping data source has been disposed.');
    }

    if (_isRunning && _progressController != null) {
      return _progressController!.stream;
    }

    _progressController?.close();
    _progressController = StreamController<DiagnosticProgressEntity>.broadcast();
    _resultCompleter = Completer<PingResultModel>();
    _latestResult = null;
    _pendingException = null;
    _subscription?.cancel();
    _subscription = null;
    _activePing = null;
    _isRunning = true;

    final controller = _progressController!;
    final samples = <double>[];
    int completedProbes = 0;

    void emitProgress({required double progress, required String message, PingResultModel? result}) {
      if (_isDisposed || controller.isClosed) {
        return;
      }
      controller.add(
        DiagnosticProgressEntity(
          stage: DiagnosticStage.runningPingTest,
          progress: progress.clamp(0.0, 1.0),
          message: message,
          timestamp: _now(),
          pingResult: result,
        ),
      );
    }

    void emitError(String message) {
      final exception = PingException(message);
      if (_resultCompleter != null && !_resultCompleter!.isCompleted) {
        _resultCompleter!.completeError(exception);
      } else {
        _pendingException = exception;
      }
      emitProgress(progress: 0.0, message: message);
      _closeController();
    }

    try {
      final ping = _pingCreator(
        host,
        count: count,
        interval: intervalSeconds,
        timeout: timeoutSeconds,
        ttl: ttl,
        ipv6: ipv6,
        forceCodepage: forceCodepageOnWindows && Platform.isWindows,
      );
      _activePing = ping;

      emitProgress(progress: 0.0, message: 'Iniciando teste de latência...');

      _subscription = ping.stream.listen(
        (event) {
          if (event.summary != null) {
            final summary = event.summary!;
            final result = _buildResult(summary: summary, samples: samples);
            _latestResult = result;
            if (_resultCompleter != null && !_resultCompleter!.isCompleted) {
              _resultCompleter!.complete(result);
            }
            emitProgress(
              progress: 1.0,
              message: 'Latência média ${result.averageLatencyMs.toStringAsFixed(1)} ms',
              result: result,
            );
            _closeController();
            return;
          }

          if (event.error != null) {
            completedProbes = (completedProbes + 1).clamp(0, count);
            emitProgress(
              progress: _calculateProgress(completedProbes),
              message: _mapError(event.error!),
            );
            return;
          }

          final response = event.response;
          if (response != null) {
            completedProbes = (completedProbes + 1).clamp(0, count);
            final duration = response.time;
            final milliseconds = duration == null
                ? 0.0
                : duration.inMicroseconds / Duration.microsecondsPerMillisecond;
            if (milliseconds > 0) {
              samples.add(milliseconds);
            }
            emitProgress(
              progress: _calculateProgress(completedProbes),
              message: 'Pacote ${response.seq ?? completedProbes}: ${milliseconds.toStringAsFixed(1)} ms',
            );
          }
        },
        onError: (error, stackTrace) {
          emitError(error is PingException ? error.message : error.toString());
        },
        onDone: () {
          if (_resultCompleter != null && !_resultCompleter!.isCompleted) {
            emitError('Resumo de ping não foi produzido.');
          }
        },
        cancelOnError: false,
      );
    } catch (error) {
      emitError(error.toString());
    }

    return controller.stream;
  }

  double _calculateProgress(int completed) {
    if (count <= 0) {
      return 0.0;
    }
    return (completed / count).clamp(0.0, 1.0);
  }

  PingResultModel _buildResult({required PingSummary summary, required List<double> samples}) {
    final transmitted = summary.transmitted;
    final received = summary.received;
    final lost = transmitted - received;
    final packetLoss = transmitted <= 0 ? 0.0 : (lost / transmitted) * 100.0;
    final safeSamples = samples.isEmpty ? <double>[] : List<double>.from(samples);
    final average = safeSamples.isEmpty
        ? 0.0
        : safeSamples.reduce((a, b) => a + b) / safeSamples.length;
    final minLatency = safeSamples.isEmpty
        ? 0.0
        : safeSamples.reduce((a, b) => a < b ? a : b);
    final maxLatency = safeSamples.isEmpty
        ? 0.0
        : safeSamples.reduce((a, b) => a > b ? a : b);
    final jitter = _calculateJitter(safeSamples);

    return PingResultModel(
      averageLatencyMs: average,
      minLatencyMs: minLatency,
      maxLatencyMs: maxLatency,
      jitterMs: jitter,
      packetLossPercentage: packetLoss,
      transmitted: transmitted,
      received: received,
      samplesMs: List<double>.unmodifiable(safeSamples),
    );
  }

  double _calculateJitter(List<double> samples) {
    if (samples.length < 2) {
      return 0.0;
    }
    double total = 0;
    for (var i = 1; i < samples.length; i++) {
      total += (samples[i] - samples[i - 1]).abs();
    }
    return total / (samples.length - 1);
  }

  String _mapError(PingError error) {
    switch (error.error) {
      case ErrorType.timeToLiveExceeded:
        return 'TTL excedido ao alcançar o destino';
      case ErrorType.requestTimedOut:
        return 'Tempo limite excedido para resposta';
      case ErrorType.unknownHost:
        return 'Host de ping desconhecido';
      case ErrorType.noReply:
        return 'Sem resposta do host de ping';
      case ErrorType.unknown:
        return error.message ?? 'Erro desconhecido no ping';
    }
  }

  void _closeController() {
    _subscription?.cancel();
    _subscription = null;
    _activePing?.stop();
    _activePing = null;
    _isRunning = false;
    if (_progressController != null && !_progressController!.isClosed) {
      _progressController!.close();
    }
  }

  @override
  Future<PingResultModel> getPingResult() {
    if (_pendingException != null) {
      return Future.error(_pendingException!);
    }

    if (_latestResult != null) {
      return Future.value(_latestResult!);
    }

    if (_isDisposed || !_isRunning) {
      throw const PingException('Nenhum teste de ping em execução.');
    }

    _resultCompleter ??= Completer<PingResultModel>();
    return _resultCompleter!.future;
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    _subscription?.cancel();
    _subscription = null;
    if (_activePing != null) {
      await _activePing!.stop();
    }
    _activePing = null;
    if (_progressController != null && !_progressController!.isClosed) {
      await _progressController!.close();
    }
  }
}
