import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maxt_diagnostic/core/config/app_config.dart';
import 'package:maxt_diagnostic/core/error/exceptions.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';
import 'package:maxt_diagnostic/data/models/final_results_model.dart'; 
import 'package:webview_flutter/webview_flutter.dart';

// --- Constants for better maintainability ---
class _SpeedTestConstants {
  static const globalTimeout = Duration(minutes: 2);
  static const postTestSequenceDelay = Duration(milliseconds: 500);
  static const jsChannelName = 'FlutterChannel';
}

// --- Type-Safe Models for JavaScript Communication ---
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
        download = (json['download'] as num?)?.toDouble(),
        upload = (json['upload'] as num?)?.toDouble(),
        ping = (json['ping'] as num?)?.toDouble(),
        jitter = (json['jitter'] as num?)?.toDouble(),
        ipInfo = json['ipInfo'] as Map<String, dynamic>? ?? {},
        aborted = json['aborted'] as bool?;
}


/// Defines the contract for the remote data source responsible for running the speed test.
abstract class SpeedTestRemoteDataSource {
  Stream<DiagnosticProgressModel> runSpeedTest();
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

  SpeedTestRemoteDataSourceImpl({required this.config}) {
    _fsmManager = _SpeedTestFsmManager();
    if (_supportsEmbeddedWebView) {
      debugPrint('[SpeedTestDS] Using speedTestUrl: ${config.speedTestUrl}');
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000));
    } else {
      debugPrint('[SpeedTestDS] WebView not supported. Using fallback.');
    }
  }

  @override
  Stream<DiagnosticProgressModel> runSpeedTest() {
    final streamController = StreamController<DiagnosticProgressModel>.broadcast();
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
      _fsmManager.handleError('WebView not supported on this platform.');
      return;
    }

    controller
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (String url) async {
          debugPrint('✅ WebView Page loaded. Initializing test script...');
          try {
            await controller.runJavaScript('window.initialize()');
            await controller.runJavaScript('window.startTest()');
            _fsmManager.transitionTo(_SpeedTestState.downloading);
          } catch (e) {
            _fsmManager.handleError('Failed to execute init scripts in JS: ${e.toString()}');
          }
        },
        onWebResourceError: (WebResourceError error) {
          _fsmManager.handleError('Error loading WebView page: ${error.description}');
        },
      ))
      ..addJavaScriptChannel(
        _SpeedTestConstants.jsChannelName,
        onMessageReceived: (JavaScriptMessage message) {
          _fsmManager.processJsMessage(message.message);
        },
      ).then((_) {
        debugPrint('🌐 JS Channel configured. Loading URL: ${config.speedTestUrl}');
        controller.loadRequest(Uri.parse(config.speedTestUrl));
      }).catchError((e) {
        _fsmManager.handleError('Critical failure configuring JS Channel: ${e.toString()}');
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
    _fsmManager.dispose();
  }

  void _runSpeedTestSimulationFallback() async {
    // This simulation can now directly interact with the FSM
    debugPrint('🧪 Running speed test simulation (fallback)...');
    _fsmManager.transitionTo(_SpeedTestState.downloading);
    await Future.delayed(const Duration(seconds: 1));
    _fsmManager.transitionTo(_SpeedTestState.uploading);
    await Future.delayed(const Duration(seconds: 1));

    final fakePayload = json.encode({
      'event': 'end',
      'payload': {
        'download': 50.0, 'upload': 20.0, 'ping': 12.0, 'jitter': 3.0,
        'ipInfo': {'isp': 'Simulated ISP'}, 'aborted': false,
      }
    });
    _fsmManager.processJsMessage(fakePayload);
  }
}


// --- FSM Logic extracted into its own class ---
enum _SpeedTestState { idle, initializing, downloading, uploading, processingEnd, completed, error }

class _SpeedTestFsmManager {
  StreamController<DiagnosticProgressModel>? _progressController;
  Completer<SpeedTestResultModel>? _resultCompleter;

  _SpeedTestState _currentState = _SpeedTestState.idle;
  double? _cachedPing;
  Timer? _globalTimeout;
  bool _explicitlyClosed = false;

  void start(StreamController<DiagnosticProgressModel> controller) {
    _progressController = controller;
    _resultCompleter = Completer<SpeedTestResultModel>();
    transitionTo(_SpeedTestState.initializing);
    _cachedPing = null;
    _explicitlyClosed = false;

    _globalTimeout = Timer(_SpeedTestConstants.globalTimeout, () {
      handleError('Test timed out (${_SpeedTestConstants.globalTimeout.inMinutes} minutes)');
    });
  }

  Future<SpeedTestResultModel> getResult() => _resultCompleter?.future ?? Future.error(const SpeedTestException('Test not started'));

  void transitionTo(_SpeedTestState newState) {
    if (_currentState == newState) return;
    debugPrint('[FSM] State transition: ${_currentState.name} -> ${newState.name}');
    _currentState = newState;
  }

  void processJsMessage(String jsonMessage) {
    if (_currentState == _SpeedTestState.completed || _currentState == _SpeedTestState.error) return;

    try {
      final message = _JsMessage.fromJson(json.decode(jsonMessage) as Map<String, dynamic>);
      debugPrint('📨 JS Message | event: ${message.event}, type: ${message.payload.type}, state: ${_currentState.name}');

      if (message.event == 'error') {
        handleError(message.payload.message ?? 'Unknown JS error');
        return;
      }
      
      if (message.event == 'end') {
        _handleEndMessage(message.payload);
        return;
      }

      switch (_currentState) {
        case _SpeedTestState.downloading:
          if (message.payload.type == 'download') {
            _emitProgress(DiagnosticStage.runningDownloadTest, message.payload.progress, 'Download: ${message.payload.speed ?? ''} Mbps');
          } else if (message.payload.type == 'upload') {
            transitionTo(_SpeedTestState.uploading);
            _emitProgress(DiagnosticStage.runningUploadTest, message.payload.progress, 'Upload: ${message.payload.speed ?? ''} Mbps');
          } else if (['ping', 'progress'].contains(message.payload.type)) {
            _cachePing(message.payload.speed);
          }
          break;
        
        case _SpeedTestState.uploading:
          if (message.payload.type == 'upload') {
            _emitProgress(DiagnosticStage.runningUploadTest, message.payload.progress, 'Upload: ${message.payload.speed ?? ''} Mbps');
          } else if (['ping', 'progress'].contains(message.payload.type)) {
            _cachePing(message.payload.speed);
          }
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint('Error decoding JS message: $e');
    }
  }

  void _handleEndMessage(_JsPayload payload) {
    if (_resultCompleter?.isCompleted ?? true) return;
    
    transitionTo(_SpeedTestState.processingEnd);

    final finalPing = _cachedPing ?? payload.ping ?? 0.0;
    
    _runPostTestSequence(
      download: payload.download ?? 0.0,
      upload: payload.upload ?? 0.0,
      ping: finalPing,
      jitter: payload.jitter ?? 0.0,
      payload: payload
    );
  }

  // ALL HELPER METHODS ARE NOW CORRECTLY INSIDE THE FSM MANAGER
  void _runPostTestSequence({required double download, required double upload, required double ping, required double jitter, required _JsPayload payload}) async {
    try {
      _emitProgress(DiagnosticStage.runningLatencyTest, 0.5, 'Latência: ${ping.toStringAsFixed(1)} ms');
      await Future.delayed(_SpeedTestConstants.postTestSequenceDelay);
      _emitProgress(DiagnosticStage.runningLatencyTest, 1.0, 'Latência concluída');
      
      _emitProgress(DiagnosticStage.runningJitterTest, 0.5, 'Jitter: ${jitter.toStringAsFixed(1)} ms');
      await Future.delayed(_SpeedTestConstants.postTestSequenceDelay);
      _emitProgress(DiagnosticStage.runningJitterTest, 1.0, 'Jitter concluído');
      
      _emitProgress(DiagnosticStage.collectingAdditionalInfo, 1.0, 'Coletando informações adicionais...');
      await Future.delayed(_SpeedTestConstants.postTestSequenceDelay);

      final result = SpeedTestResultModel(
        downloadSpeed: download, uploadSpeed: upload, ping: ping, jitter: jitter,
        serverLocation: payload.ipInfo['isp'] as String? ?? 'Servidor Interno',
        testStartTime: DateTime.now().subtract(const Duration(seconds: 30)), 
        testEndTime: DateTime.now(), testCompleted: !(payload.aborted ?? false),
      );

      if (!(_resultCompleter?.isCompleted ?? true)) {
        _resultCompleter?.complete(result);
      }
      
      _emitProgress(DiagnosticStage.completed, 1.0, 'Teste concluído!');
      transitionTo(_SpeedTestState.completed);

      await Future.delayed(const Duration(milliseconds: 100));
      dispose();
    } catch (e) {
      handleError('Error in post-test sequence: $e');
    }
  }

  void handleError(String message) {
    if (_resultCompleter?.isCompleted ?? true) return;
    
    transitionTo(_SpeedTestState.error);
    _emitProgress(DiagnosticStage.error, 0.0, message);
    
    if (!(_resultCompleter?.isCompleted ?? true)) {
      _resultCompleter?.complete(SpeedTestResultModel.error(message));
    }
    dispose();
  }
  
  void dispose() {
    debugPrint('♻️ FSM Dispose called. State: ${_currentState.name}, ExplicitlyClosed: $_explicitlyClosed');
    _globalTimeout?.cancel();
    if (_progressController != null && !_progressController!.isClosed) {
      _explicitlyClosed = true;
      _progressController!.close();
    }
  }

  void _emitProgress(DiagnosticStage stage, double progress, String message) {
    if (_progressController?.isClosed == false) {
      _progressController!.add(DiagnosticProgressModel(
        stage: stage, progress: progress, message: message, timestamp: DateTime.now(),
      ));
    }
  }

  void _cachePing(dynamic speed) {
    if (speed != null && speed.toString().isNotEmpty) {
      final pingValue = double.tryParse(speed.toString());
      if (pingValue != null) {
        _cachedPing = pingValue;
        debugPrint('📋 Ping cached: ${_cachedPing}ms');
      }
    }
  }
}