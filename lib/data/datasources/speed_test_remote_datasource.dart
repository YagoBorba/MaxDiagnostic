import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/error/exceptions.dart';
import '../models/final_results_model.dart';
import '../../domain/entities/final_results_entity.dart';

/// Abstract contract for speed test data source
abstract class SpeedTestRemoteDataSource {
  Stream<DiagnosticProgressModel> runSpeedTest();
  Future<SpeedTestResultModel> getSpeedTestResult();
}

/// Implementation of speed test data source using WebView
/// Communicates with LibreSpeed instance via JavaScript bridge
class SpeedTestRemoteDataSourceImpl implements SpeedTestRemoteDataSource {
  static const String _speedTestUrl = 'http://10.254.254.222:7000/librespeed_runner.html';
  
  WebViewController? _controller;
  StreamController<DiagnosticProgressModel>? _progressController;
  Completer<SpeedTestResultModel>? _resultCompleter;

  @override
  Stream<DiagnosticProgressModel> runSpeedTest() {
    _progressController = StreamController<DiagnosticProgressModel>();
    _resultCompleter = Completer<SpeedTestResultModel>();
    
    _initializeWebView();
    
    return _progressController!.stream;
  }

  @override
  Future<SpeedTestResultModel> getSpeedTestResult() {
    if (_resultCompleter == null) {
      throw SpeedTestException('Speed test not started');
    }
    return _resultCompleter!.future;
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            _emitProgress(
              DiagnosticStage.startingSpeedTest,
              progress / 100.0,
              'Carregando teste de velocidade...',
            );
          },
          onPageStarted: (String url) {
            _emitProgress(
              DiagnosticStage.initializing,
              0.0,
              'Iniciando teste de velocidade...',
            );
          },
          onPageFinished: (String url) {
            _setupJavaScriptChannels();
            _startSpeedTest();
          },
          onWebResourceError: (WebResourceError error) {
            _handleError('Erro ao carregar página: ${error.description}');
          },
        ),
      );

    _loadSpeedTestPage();
  }

  void _setupJavaScriptChannels() {
    _controller!.addJavaScriptChannel(
      'FlutterSpeedTest',
      onMessageReceived: (JavaScriptMessage message) {
        _handleJavaScriptMessage(message.message);
      },
    );
  }

  void _loadSpeedTestPage() {
    try {
      _controller!.loadRequest(Uri.parse(_speedTestUrl));
    } catch (e) {
      _handleError('Falha ao carregar teste de velocidade: ${e.toString()}');
    }
  }

  void _startSpeedTest() {
    const jsCode = '''
      // Setup communication bridge
      window.postMessageToFlutter = function(data) {
        FlutterSpeedTest.postMessage(JSON.stringify(data));
      };
      
      // Start the speed test
      if (typeof startSpeedTest === 'function') {
        startSpeedTest();
      } else {
        window.postMessageToFlutter({
          type: 'error',
          message: 'Speed test function not found'
        });
      }
    ''';

    _controller!.runJavaScript(jsCode).catchError((error) {
      _handleError('Erro ao executar JavaScript: ${error.toString()}');
    });
  }

  void _handleJavaScriptMessage(String message) {
    try {
      final data = json.decode(message) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'progress':
          _handleProgressMessage(data);
          break;
        case 'result':
          _handleResultMessage(data);
          break;
        case 'error':
          _handleError(data['message'] as String? ?? 'Erro desconhecido');
          break;
        default:
          // TODO: Replace with proper logging framework
          // ignore: avoid_print
          print('Unknown message type: $type');
      }
    } catch (e) {
      _handleError('Erro ao processar mensagem: ${e.toString()}');
    }
  }

  void _handleProgressMessage(Map<String, dynamic> data) {
    final stage = _mapStringToStage(data['stage'] as String? ?? '');
    final progress = (data['progress'] as num?)?.toDouble() ?? 0.0;
    final message = data['message'] as String? ?? '';

    _emitProgress(stage, progress, message);
  }

  void _handleResultMessage(Map<String, dynamic> data) {
    try {
      final result = SpeedTestResultModel(
        downloadSpeed: (data['downloadSpeed'] as num?)?.toDouble() ?? 0.0,
        uploadSpeed: (data['uploadSpeed'] as num?)?.toDouble() ?? 0.0,
        ping: (data['ping'] as num?)?.toDouble() ?? 0.0,
        jitter: (data['jitter'] as num?)?.toDouble() ?? 0.0,
        serverLocation: data['serverLocation'] as String? ?? 'Unknown',
        testStartTime: DateTime.now().subtract(const Duration(minutes: 1)),
        testEndTime: DateTime.now(),
        testCompleted: true,
      );

      _emitProgress(
        DiagnosticStage.completed,
        1.0,
        'Teste concluído com sucesso!',
      );

      _resultCompleter?.complete(result);
      _progressController?.close();
    } catch (e) {
      _handleError('Erro ao processar resultado: ${e.toString()}');
    }
  }

  void _handleError(String errorMessage) {
    _emitProgress(
      DiagnosticStage.error,
      0.0,
      errorMessage,
    );

    final errorResult = SpeedTestResultModel(
      downloadSpeed: 0.0,
      uploadSpeed: 0.0,
      ping: 0.0,
      jitter: 0.0,
      serverLocation: 'Error',
      testStartTime: DateTime.now(),
      testEndTime: DateTime.now(),
      testCompleted: false,
      errorMessage: errorMessage,
    );

    _resultCompleter?.complete(errorResult);
    _progressController?.close();
  }

  void _emitProgress(DiagnosticStage stage, double progress, String message) {
    if (_progressController?.isClosed == false) {
      _progressController!.add(
        DiagnosticProgressModel(
          stage: stage,
          progress: progress,
          message: message,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  DiagnosticStage _mapStringToStage(String stageString) {
    switch (stageString.toLowerCase()) {
      case 'download':
        return DiagnosticStage.runningDownloadTest;
      case 'upload':
        return DiagnosticStage.runningUploadTest;
      case 'ping':
        return DiagnosticStage.runningPingTest;
      case 'starting':
        return DiagnosticStage.startingSpeedTest;
      case 'completed':
        return DiagnosticStage.completed;
      default:
        return DiagnosticStage.startingSpeedTest;
    }
  }

  void dispose() {
    _progressController?.close();
    _resultCompleter = null;
    _controller = null;
  }
}
