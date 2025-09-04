import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maxt_diagnostic/core/config/app_config.dart';
import 'package:maxt_diagnostic/core/error/exceptions.dart';
import 'package:maxt_diagnostic/domain/entities/diagnostic_flow.dart';
import 'package:maxt_diagnostic/data/models/final_results_model.dart';
import 'package:webview_flutter/webview_flutter.dart';

class _SpeedTestConstants {
  static const globalTimeout = Duration(minutes: 2);
  static const jsChannelName = 'FlutterChannel';
}

class _JsMessage {
  final String event;
  final _JsPayload payload;

  _JsMessage({required this.event, required this.payload});

  factory _JsMessage.fromJson(Map<String, dynamic> json) {
    return _JsMessage(
      event: json['event'] as String? ?? '',
      payload: _JsPayload.fromJson(json['payload'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class _JsPayload {
  final String type;
  final double progress;
  final dynamic speed;
  final String? message;
  final double? download;
  final double? upload;
  final double? ping;
  final double? jitter;
  final Map<String, dynamic> ipInfo;
  final bool? aborted;

  _JsPayload.fromJson(Map<String, dynamic> json)
      : type = (json['type'] as String? ?? '').toLowerCase(),
        progress = (json['progress'] as num?)?.toDouble() ?? 0.0,
        speed = json['speed'],
        message = json['message'] as String?,
        download = double.tryParse(json['download'].toString()),
        upload = double.tryParse(json['upload'].toString()),
        ping = double.tryParse(json['ping'].toString()),
        jitter = double.tryParse(json['jitter'].toString()),
        ipInfo = json['ipInfo'] as Map<String, dynamic>? ?? {},
        aborted = json['aborted'] as bool?;
}


abstract class SpeedTestRemoteDataSource {
  Stream<DiagnosticProgressEntity> runSpeedTest();
  Future<SpeedTestResultModel> getSpeedTestResult();
  Widget get widget;
  void dispose();
}


class SpeedTestRemoteDataSourceImpl implements SpeedTestRemoteDataSource {
  final AppConfig config;
  final bool _supportsEmbeddedWebView = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  WebViewController? _controller;
  late final _SpeedTestFsmManager _fsmManager;
  bool _isDisposed = false;

  SpeedTestRemoteDataSourceImpl({required this.config}) {
    _fsmManager = _SpeedTestFsmManager();
    if (_supportsEmbeddedWebView) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000));
      
      if (kDebugMode) {
        debugPrint('🔧 WebView debugging enabled for development');        
      }
    } else {
        debugPrint('[SpeedTestDS] WebView not supported. Using fallback.');
    }
  }

  @override
  Stream<DiagnosticProgressEntity> runSpeedTest() {
    final streamController = StreamController<DiagnosticProgressEntity>.broadcast();
    _fsmManager.start(streamController);

    if (kIsWeb || !_supportsEmbeddedWebView) {
      _runSpeedTestSimulationFallback();
    } else {
      _initializeAndRunWebViewTest();
    }
    
    return streamController.stream;
  }

  @override
  Future<SpeedTestResultModel> getSpeedTestResult() {
    return _fsmManager.getResult();
  }

  void _initializeAndRunWebViewTest() {
    final controller = _controller;
    if (controller == null) {
      _fsmManager.onWebViewError('WebView not supported on this platform.');
      return;
    }

    controller
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (String url) async {
          if (_isDisposed) return;
          debugPrint('✅ WebView Page loaded. Initializing test script...');
          try {
            await controller.runJavaScript('window.initialize()');
            await controller.runJavaScript('window.startTest()');
            _fsmManager.onWebViewLoaded(); 
          } catch (e) {
            _fsmManager.onWebViewError('Failed to execute init scripts in JS: ${e.toString()}');
          }
        },
        onWebResourceError: (WebResourceError error) {
          if (_isDisposed) return;
          
          debugPrint('🚨 WebView Resource Error Caught!');
          debugPrint('           Failed URL: ${error.url}');
          debugPrint('          Error Code: ${error.errorCode}');
          debugPrint('         Description: ${error.description}');
          debugPrint('          Error Type: ${error.errorType}');
          debugPrint(' Is for main frame?: ${error.isForMainFrame}');

          _fsmManager.onWebViewError('Error loading resource: ${error.description} (URL: ${error.url}, Code: ${error.errorCode})');
        },
      ))
      ..addJavaScriptChannel(
        _SpeedTestConstants.jsChannelName,
        onMessageReceived: (JavaScriptMessage message) {
          if (_isDisposed) return;
          _fsmManager.onJsMessage(message.message); 
        },
      ).then((_) async {
        if (_isDisposed) return;
        
        final cacheBuster = DateTime.now().millisecondsSinceEpoch;
        final url = "${config.speedTestUrl}?v=$cacheBuster";

        debugPrint('🌐 JS Channel configured. Clearing cache and loading URL: $url');

        await controller.clearCache();
        await controller.loadRequest(Uri.parse(url));

      }).catchError((e) {
        if (_isDisposed) return;
        _fsmManager.onWebViewError('Critical failure configuring JS Channel: ${e.toString()}');
      });
  }

  @override
  Widget get widget {
    if (kIsWeb || !_supportsEmbeddedWebView) {
      return const SizedBox.shrink();
    }
    return Offstage(offstage: true, child: WebViewWidget(controller: _controller!));
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    debugPrint('♻️ DataSource Dispose called.');
    _controller?.runJavaScript('if(window.speedtest) window.speedtest.abort();').catchError((_) {
        debugPrint("Failed to send abort signal to JS, it might have been cleaned up already.");
    });
    _fsmManager.dispose();
  }

  void _runSpeedTestSimulationFallback() async {
    debugPrint('🧪 Running speed test simulation (fallback)...');
    _fsmManager.onWebViewLoaded(); 
    await Future.delayed(const Duration(seconds: 1));
    final fakePayload = json.encode({
      'event': 'end',
      'payload': {
        'download': '50.0', 'upload': '20.0', 'ping': '12.0', 'jitter': '3.0',
        'ipInfo': {'isp': 'Simulated ISP'}, 'aborted': false,
      }
    });
    _fsmManager.onJsMessage(fakePayload);
  }
}

enum _SpeedTestState { idle, initializing, running, completed, error }

class _SpeedTestFsmManager {
  StreamController<DiagnosticProgressEntity>? _progressController;
  Completer<SpeedTestResultModel>? _resultCompleter;
  Timer? _globalTimeout;

  _SpeedTestState _currentState = _SpeedTestState.idle;

  void start(StreamController<DiagnosticProgressEntity> controller) {
    _progressController = controller;
    _resultCompleter = Completer<SpeedTestResultModel>();
    transitionTo(_SpeedTestState.initializing);

    _globalTimeout = Timer(_SpeedTestConstants.globalTimeout, () {
      handleError('Test timed out (${_SpeedTestConstants.globalTimeout.inMinutes} minutes)');
    });
  }

  Future<SpeedTestResultModel> getResult() => _resultCompleter?.future ?? Future.error(const SpeedTestException('Test not started'));

  void onWebViewLoaded() {
    if (_currentState == _SpeedTestState.initializing) {
      transitionTo(_SpeedTestState.running);
      _emitProgress(DiagnosticStage.initializing, 1.0, 'Conexão com servidor estabelecida. Iniciando testes...');
    }
  }

  void onWebViewError(String message) {
    handleError(message);
  }

  void onJsMessage(String jsonMessage) {
    if (_currentState != _SpeedTestState.running) return;

    try {
      final message = _JsMessage.fromJson(json.decode(jsonMessage) as Map<String, dynamic>);
      debugPrint('📨 JS Message | event: ${message.event}, type: ${message.payload.type}');

      switch (message.event) {
        case 'error':
          debugPrint('🚨 JS Error Event | message: ${message.payload.message}');
          handleError(message.payload.message ?? 'Unknown JS error');
          break;
        case 'end':
          debugPrint('✅ JS End Event | aborted: ${message.payload.aborted}, download: ${message.payload.download}, upload: ${message.payload.upload}');
          _handleEndMessage(message.payload);
          break;
        case 'progress':
          _handleProgressMessage(message.payload);
          break;
        default:
          debugPrint('⚠️ Unknown JS Event: ${message.event}');
      }
    } catch (e) {
      debugPrint('🚨 Error decoding JS message: $e');
      debugPrint('🚨 Raw message was: $jsonMessage');
      handleError('Invalid message format from WebView: $e');
    }
  }

  void _handleProgressMessage(_JsPayload payload) {
    DiagnosticStage stage;
    String text;

    switch(payload.type) {
      case 'download':
        stage = DiagnosticStage.runningDownloadTest;
        text = 'Download: ${payload.speed ?? ''} Mbps';
        break;
      case 'upload':
        stage = DiagnosticStage.runningUploadTest;
        text = 'Upload: ${payload.speed ?? ''} Mbps';
        break;
      case 'ping':
        stage = DiagnosticStage.runningLatencyTest;
        text = 'Latência: ${payload.speed ?? ''} ms';
        break;
      default:
        return;
    }
    _emitProgress(stage, payload.progress, text);
  }

  void _handleEndMessage(_JsPayload payload) {
    if (_currentState == _SpeedTestState.completed || _currentState == _SpeedTestState.error) return;
    transitionTo(_SpeedTestState.completed);

    final result = SpeedTestResultModel(
      downloadSpeed: payload.download ?? 0.0,
      uploadSpeed: payload.upload ?? 0.0,
      ping: payload.ping ?? 0.0,
      jitter: payload.jitter ?? 0.0,
      serverLocation: payload.ipInfo['isp'] as String? ?? 'Servidor Interno',
      testStartTime: DateTime.now().subtract(const Duration(seconds: 30)),
      testEndTime: DateTime.now(),
      testCompleted: !(payload.aborted ?? false),
    );

    if (!(_resultCompleter?.isCompleted ?? true)) {
      _resultCompleter?.complete(result);
    }
    
    _emitProgress(DiagnosticStage.completed, 1.0, 'Teste concluído!', result: result);
    dispose();
  }

  void handleError(String message) {
    if (_currentState == _SpeedTestState.completed || _currentState == _SpeedTestState.error) return;
    
    debugPrint('🚨 Speed Test Error | Current State: ${_currentState.name}');
    debugPrint('🚨 Error Message: $message');
    
    transitionTo(_SpeedTestState.error);
    
    _emitProgress(DiagnosticStage.error, 0.0, message);
    
    if (!(_resultCompleter?.isCompleted ?? true)) {
      _resultCompleter?.completeError(SpeedTestException(message), StackTrace.current);
    }
    dispose();
  }
  
  void dispose() {
    debugPrint('♻️ FSM Dispose called. State: ${_currentState.name}');
    _globalTimeout?.cancel();
    if (_currentState != _SpeedTestState.completed && _currentState != _SpeedTestState.error) {
      if (!(_resultCompleter?.isCompleted ?? true)) {
         _resultCompleter?.completeError(const SpeedTestException("Test cancelled by user"), StackTrace.current);
      }
    }
    _progressController?.close();
  }

  void transitionTo(_SpeedTestState newState) {
    if (_currentState == newState) return;
    debugPrint('[FSM] State transition: ${_currentState.name} -> ${newState.name}');
    _currentState = newState;
  }

  void _emitProgress(DiagnosticStage stage, double progress, String message, {SpeedTestResultModel? result}) {
    if (_progressController?.isClosed == false) {
      _progressController!.add(DiagnosticProgressEntity(
        stage: stage,
        progress: progress,
        message: message,
        timestamp: DateTime.now(),
        speedTestResult: result,
      ));
    }
  }
}