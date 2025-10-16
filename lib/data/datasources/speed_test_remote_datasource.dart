import 'dart:async';

import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';
// ignore: implementation_imports
import 'package:flutter_internet_speed_test/src/flutter_internet_speed_test_platform_interface.dart'
  as fist;

import '../../core/config/app_config.dart';
import '../../core/error/exceptions.dart';
import '../../domain/entities/diagnostic_flow.dart';
import '../models/speed_test_result_model.dart';

typedef CancelListening = void Function();

abstract class SpeedTestClient {
  Future<CancelListening> startDownloadTesting({
    required fist.DoneCallback onDone,
    required fist.ProgressCallback onProgress,
    required fist.ErrorCallback onError,
    required int fileSize,
    required String testServer,
  });

  Future<CancelListening> startUploadTesting({
    required fist.DoneCallback onDone,
    required fist.ProgressCallback onProgress,
    required fist.ErrorCallback onError,
    required int fileSize,
    required String testServer,
  });
}

class FlutterSpeedTestClient implements SpeedTestClient {
  FlutterSpeedTestClient({fist.FlutterInternetSpeedTestPlatform? platform})
      : _platform = platform ?? fist.FlutterInternetSpeedTestPlatform.instance;

  final fist.FlutterInternetSpeedTestPlatform _platform;

  @override
  Future<CancelListening> startDownloadTesting({
    required fist.DoneCallback onDone,
    required fist.ProgressCallback onProgress,
    required fist.ErrorCallback onError,
    required int fileSize,
    required String testServer,
  }) {
    return _platform.startDownloadTesting(
      onDone: onDone,
      onProgress: onProgress,
      onError: onError,
      fileSize: fileSize,
      testServer: testServer,
    );
  }

  @override
  Future<CancelListening> startUploadTesting({
    required fist.DoneCallback onDone,
    required fist.ProgressCallback onProgress,
    required fist.ErrorCallback onError,
    required int fileSize,
    required String testServer,
  }) {
    return _platform.startUploadTesting(
      onDone: onDone,
      onProgress: onProgress,
      onError: onError,
      fileSize: fileSize,
      testServer: testServer,
    );
  }
}

abstract class SpeedTestRemoteDataSource {
  Stream<DiagnosticProgressEntity> runSpeedTest();
  Future<SpeedTestResultModel> getSpeedTestResult();
  void dispose();
}

class SpeedTestRemoteDataSourceImpl implements SpeedTestRemoteDataSource {
  SpeedTestRemoteDataSourceImpl({
    required this.config,
    SpeedTestClient? speedTestClient,
    DateTime Function()? now,
  })  : _client = speedTestClient ?? FlutterSpeedTestClient(),
        _now = now ?? DateTime.now;

  final AppConfig config;
  final SpeedTestClient _client;
  final DateTime Function() _now;

  StreamController<DiagnosticProgressEntity>? _progressController;
  Completer<SpeedTestResultModel>? _resultCompleter;
  SpeedTestResultModel? _latestResult;
  SpeedTestException? _pendingException;
  CancelListening? _downloadCancel;
  CancelListening? _uploadCancel;
  bool _isDisposed = false;
  bool _isRunning = false;

  double? _downloadMbps;
  double? _uploadMbps;
  DateTime? _startTime;

  @override
  Stream<DiagnosticProgressEntity> runSpeedTest() {
    if (_isDisposed) {
      throw const SpeedTestException('Speed test data source has been disposed.');
    }

    if (_isRunning && _progressController != null) {
      return _progressController!.stream;
    }

    _progressController?.close();
    _progressController = StreamController<DiagnosticProgressEntity>.broadcast();
    _resultCompleter = null;
    _latestResult = null;
    _pendingException = null;
    _startTime = _now();
    _downloadMbps = null;
    _uploadMbps = null;
    _isRunning = true;

    final controller = _progressController!;

    void emitProgress(
      DiagnosticStage stage,
      double progress,
      String message, {
      SpeedTestResultModel? result,
    }) {
      if (_isDisposed || controller.isClosed) {
        return;
      }
      controller.add(
        DiagnosticProgressEntity(
          stage: stage,
          progress: progress.clamp(0.0, 1.0),
          message: message,
          timestamp: _now(),
          speedTestResult: result,
        ),
      );
    }

    void emitError(String message) {
      final exception = SpeedTestException(message);
      if (_resultCompleter != null && !_resultCompleter!.isCompleted) {
        _resultCompleter!.completeError(exception);
        _resultCompleter = null;
      } else {
        _pendingException = exception;
      }
      emitProgress(DiagnosticStage.error, 0.0, message);
      _closeController();
    }

    Future<void> startDownload() async {
      try {
        _downloadCancel = await _client.startDownloadTesting(
          onProgress: (percent, transferRate, unit) {
            final speed = _convertToMbps(transferRate, unit);
            _downloadMbps = speed;
            emitProgress(
              DiagnosticStage.runningDownloadTest,
              percent / 100,
              'Download ${speed.toStringAsFixed(2)} Mbps (${percent.toStringAsFixed(0)}%)',
            );
          },
          onDone: (transferRate, unit) {
            final speed = _convertToMbps(transferRate, unit);
            _downloadMbps = speed;
            emitProgress(
              DiagnosticStage.runningDownloadTest,
              1.0,
              'Download concluído em ${speed.toStringAsFixed(2)} Mbps',
            );
            unawaited(_startUploadTest(emitProgress, emitError));
          },
          onError: (errorMessage, speedTestError) {
            emitError(_mapErrorMessage(errorMessage, speedTestError));
          },
          fileSize: config.speedTestFileSizeBytes,
          testServer: config.speedTestDownloadUrl,
        );
      } catch (error) {
        emitError(error.toString());
      }
    }

    Future.microtask(() {
      emitProgress(
        DiagnosticStage.startingSpeedTest,
        0.0,
        'Iniciando teste de velocidade...',
      );
    });

    unawaited(Future.microtask(startDownload));

    return controller.stream;
  }

  Future<void> _startUploadTest(
    void Function(DiagnosticStage, double, String, {SpeedTestResultModel? result}) emitProgress,
    void Function(String message) emitError,
  ) async {
    emitProgress(
      DiagnosticStage.runningUploadTest,
      0.0,
      'Iniciando teste de upload...',
    );

    try {
      _uploadCancel = await _client.startUploadTesting(
        onProgress: (percent, transferRate, unit) {
          final speed = _convertToMbps(transferRate, unit);
          _uploadMbps = speed;
          emitProgress(
            DiagnosticStage.runningUploadTest,
            percent / 100,
            'Upload ${speed.toStringAsFixed(2)} Mbps (${percent.toStringAsFixed(0)}%)',
          );
        },
        onDone: (transferRate, unit) {
          final speed = _convertToMbps(transferRate, unit);
          _uploadMbps = speed;
          emitProgress(
            DiagnosticStage.runningUploadTest,
            1.0,
            'Upload concluído em ${speed.toStringAsFixed(2)} Mbps',
          );
          _completeTest(emitProgress);
        },
        onError: (errorMessage, speedTestError) {
          emitError(_mapErrorMessage(errorMessage, speedTestError));
        },
        fileSize: config.speedTestFileSizeBytes,
        testServer: config.speedTestUploadUrl,
      );
    } catch (error) {
      emitError(error.toString());
    }
  }

  void _completeTest(
    void Function(DiagnosticStage, double, String, {SpeedTestResultModel? result}) emitProgress,
  ) {
    final endTime = _now();
    final result = SpeedTestResultModel(
      downloadSpeed: _downloadMbps ?? 0,
      uploadSpeed: _uploadMbps ?? 0,
      ping: 0,
      jitter: 0,
      serverLocation: config.speedTestUrl,
      testStartTime: _startTime ?? endTime,
      testEndTime: endTime,
      testCompleted: true,
    );

    if (_resultCompleter != null && !_resultCompleter!.isCompleted) {
      _resultCompleter!.complete(result);
      _resultCompleter = null;
    } else {
      _latestResult = result;
    }

    emitProgress(
      DiagnosticStage.completed,
      1.0,
      'Teste de velocidade concluído com sucesso.',
      result: result,
    );

    _closeController();
  }

  double _convertToMbps(double transferRate, SpeedUnit unit) {
    if (unit == SpeedUnit.Mbps) return transferRate;
    if (unit == SpeedUnit.Kbps) return transferRate / 1000;
    return transferRate;
  }

  String _mapErrorMessage(String message, String code) {
    if (code.isEmpty) return message;
    return '$message (código: $code)';
  }

  void _closeController() {
    _downloadCancel?.call();
    _downloadCancel = null;
    _uploadCancel?.call();
    _uploadCancel = null;
    _isRunning = false;
    if (_progressController != null && !_progressController!.isClosed) {
      _progressController!.close();
    }
  }

  @override
  Future<SpeedTestResultModel> getSpeedTestResult() {
    if (_pendingException != null) {
      return Future.error(_pendingException!);
    }

    if (_latestResult != null) {
      return Future.value(_latestResult!);
    }

    if (_isDisposed || !_isRunning) {
      throw const SpeedTestException('Nenhum teste de velocidade em execução.');
    }

    _resultCompleter ??= Completer<SpeedTestResultModel>();
    return _resultCompleter!.future;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _closeController();
  }
}