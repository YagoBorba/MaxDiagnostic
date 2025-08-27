import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/error/exceptions.dart';
import '../../core/config/app_config.dart';
import '../models/final_results_model.dart';
import '../../domain/entities/final_results_entity.dart';

abstract class SpeedTestRemoteDataSource {
  Stream<DiagnosticProgressModel> runSpeedTest();
  Future<SpeedTestResultModel> getSpeedTestResult();
  Widget get widget;
}

class SpeedTestRemoteDataSourceImpl implements SpeedTestRemoteDataSource {
  final AppConfig config;

  SpeedTestRemoteDataSourceImpl({required this.config});

  WebViewController? _controller;
  StreamController<DiagnosticProgressModel>? _progressController;
  Completer<SpeedTestResultModel>? _resultCompleter;
  // Keep only the controller as state; build the widget on demand.

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
      throw const SpeedTestException('Speed test not started');
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
      final url = config.speedTestUrl;
      _controller!.loadRequest(Uri.parse(url));
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
      (function(){
        function send(type, payload){
          window.postMessageToFlutter(Object.assign({ type: type }, payload || {}));
        }

        try {
          // Expected LibreSpeed integration API
          if (typeof startSpeedTest === 'function') {
            startSpeedTest();
          } else if (typeof window.libreSpeedStart === 'function') {
            window.libreSpeedStart();
          } else {
            send('error', { message: 'Speed test function not found' });
          }

          // If the page exposes a global event emitter, hook it
          if (window.addEventListener) {
            window.addEventListener('librespeed-progress', function(e){
              var d = e && e.detail ? e.detail : {};
              send('progress', {
                stage: d.stage || d.phase || 'starting',
                progress: d.progress || d.p || 0,
                message: d.message || d.msg || ''
              });
            });

            window.addEventListener('librespeed-end', function(e){
              var r = e && e.detail ? e.detail : {};
              send('end', { results: r });
            });
          }
        } catch (err) {
          send('error', { message: String(err && err.message || err) });
        }
      })();
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
        case 'end':
          _handleResultMessage(data);
          break;
        case 'error':
          _handleError(data['message'] as String? ?? 'Erro desconhecido');
          break;
        default:
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
      final payload = (data['results'] is Map<String, dynamic>)
          ? (data['results'] as Map<String, dynamic>)
          : data;

      final result = SpeedTestResultModel(
        downloadSpeed: (payload['download'] as num? ?? payload['downloadSpeed'])?.toDouble() ?? 0.0,
        uploadSpeed: (payload['upload'] as num? ?? payload['uploadSpeed'])?.toDouble() ?? 0.0,
        ping: (payload['ping'] as num?)?.toDouble() ?? 0.0,
        jitter: (payload['jitter'] as num?)?.toDouble() ?? 0.0,
        serverLocation: payload['server'] as String? ?? payload['serverLocation'] as String? ?? 'Unknown',
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

  @override
  Widget get widget {
    _controller ??= (WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(NavigationDelegate()));
    return WebViewWidget(controller: _controller!);
  }
}
