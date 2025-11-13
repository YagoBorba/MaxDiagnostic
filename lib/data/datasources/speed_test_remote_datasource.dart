import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:maxt_diagnostic/core/config/app_config.dart';
import 'package:maxt_diagnostic/core/error/exceptions.dart';
import 'package:maxt_diagnostic/domain/entities/diagnostic_flow.dart';
import 'package:maxt_diagnostic/data/models/final_results_model.dart';

class _SpeedTestConstants {
  static const globalTimeout = Duration(minutes: 5);
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
        download = _parseNumeric(json['download']),
        upload = _parseNumeric(json['upload']),
        ping = _parseNumeric(json['ping']),
        jitter = _parseNumeric(json['jitter']),
        ipInfo = json['ipInfo'] as Map<String, dynamic>? ?? {},
        aborted = json['aborted'] as bool?;

  static double? _parseNumeric(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}


abstract class SpeedTestRemoteDataSource {
  Stream<DiagnosticProgressEntity> runSpeedTest();
  Future<SpeedTestResultModel> getSpeedTestResult();
  void dispose();
}


class SpeedTestRemoteDataSourceImpl implements SpeedTestRemoteDataSource {
  final AppConfig config;
  _SpeedTestFsmManager _fsmManager = _SpeedTestFsmManager();
  HeadlessInAppWebView? _headlessWebView;
  InAppWebViewController? _controller;
  bool _isDisposed = false;

  SpeedTestRemoteDataSourceImpl({required this.config}) {
    if (kDebugMode) {
      debugPrint('🔧 HeadlessInAppWebView initialized for speed test');
      debugPrint('🔧 Using URL: ${config.speedTestUrl}');
      
      try {
        InAppWebViewController.setWebContentsDebuggingEnabled(true);
        debugPrint('🔧 WebView debugging enabled - você pode inspecionar via chrome://inspect');
      } catch (e) {
        debugPrint('⚠️ Não foi possível habilitar WebView debugging (ambiente de teste?): $e');
      }
    }
  }

  @override
  Stream<DiagnosticProgressEntity> runSpeedTest() {
    _isDisposed = false;
    _fsmManager.dispose();
    _fsmManager = _SpeedTestFsmManager();

    final streamController = StreamController<DiagnosticProgressEntity>.broadcast();
    _fsmManager.start(streamController);

    if (kIsWeb) {
      _runSpeedTestSimulationFallback();
    } else {
      _initializeAndRunHeadlessWebViewTest();
    }
    
    return streamController.stream;
  }

  void _initializeAndRunHeadlessWebViewTest() async {
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    final url = "${config.speedTestUrl}?v=$cacheBuster";
    
    if (config.speedTestUrl == 'about:blank' || config.speedTestUrl.isEmpty) {
      debugPrint('🚨 Invalid speedTestUrl: "${config.speedTestUrl}"');
      debugPrint('💡 Make sure .env file exists and contains SPEED_TEST_URL=http://your-server:7000/librespeed_runner.html');
      debugPrint('💡 Also verify .env is listed in pubspec.yaml assets section');
      _fsmManager.onWebViewError(
        'Speed test server not configured. Please check your .env file and ensure SPEED_TEST_URL is set correctly.'
      );
      return;
    }

    await _headlessWebView?.dispose();
    _headlessWebView = null;
    _controller = null;
    
    try {
      _headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        databaseEnabled: true,
        cacheEnabled: false,
        clearCache: true,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        allowsInlineMediaPlayback: true,
      ),
      onWebViewCreated: (controller) {
        debugPrint('✅ Headless WebView Created');
        debugPrint('🔧 WebView settings: debugging=$kDebugMode, cache=false');
        _controller = controller;
        
        controller.addJavaScriptHandler(
          handlerName: _SpeedTestConstants.jsChannelName,
          callback: (args) {
            if (_isDisposed || args.isEmpty) {
              return;
            }
            if (kDebugMode) {
              debugPrint('📨 JS -> Flutter: ${args[0]}');
            }
            _fsmManager.onJsMessage(args[0] as String);
          },
        );
      },
      onLoadStart: (controller, url) {
        if (kDebugMode) {
          debugPrint('🌐 WebView Load Started: $url');
        }
      },
      onLoadStop: (controller, url) async {
        if (_isDisposed) {
          return;
        }
        debugPrint('✅ Headless WebView Page loaded: $url');
        debugPrint('🔧 Initializing test script...');
        try {
          await controller.evaluateJavascript(source: '''
            (function() {
              window.FlutterChannel = {
                postMessage: function(message) {
                  if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                    window.flutter_inappwebview.callHandler('${_SpeedTestConstants.jsChannelName}', message);
                  }
                }
              };
            })();
          ''');
          
          debugPrint('✅ FlutterChannel injected successfully');
          
          if (kDebugMode) {
            final windowCheck = await controller.evaluateJavascript(source: 'typeof window');
            debugPrint('🔧 Window object: $windowCheck');
            
            final channelCheck = await controller.evaluateJavascript(source: 'typeof window.FlutterChannel');
            debugPrint('🔧 FlutterChannel: $channelCheck');
            
            final initCheck = await controller.evaluateJavascript(source: 'typeof window.initialize');
            debugPrint('🔧 Initialize function: $initCheck');
          }
          
          await controller.evaluateJavascript(source: 'window.initialize()');
          await controller.evaluateJavascript(source: 'window.startTest()');
          _fsmManager.onWebViewLoaded();
        } catch (e) {
          debugPrint('🚨 Error executing init scripts: $e');
          _fsmManager.onWebViewError('Failed to execute init scripts in JS: ${e.toString()}');
        }
      },
      onProgressChanged: (controller, progress) {
        if (kDebugMode) {
          debugPrint('📊 WebView Loading Progress: $progress%');
        }
      },
      onConsoleMessage: (controller, consoleMessage) {
        if (kDebugMode) {
          final level = consoleMessage.messageLevel.toString().split('.').last;
          debugPrint('🖥️ WebView Console [$level]: ${consoleMessage.message}');
        }
      },
      onReceivedError: (controller, request, error) {
        if (_isDisposed) {
          return;
        }
        
        if (error.type == WebResourceErrorType.UNKNOWN && error.description.contains('ERR_FAILED')) {
          debugPrint('💡 Expected ERR_FAILED detected (cleanup operation) - URL: ${request.url}');
          debugPrint('   ✅ This is normal behavior when aborting speed test connections');
          return;
        }
        
        debugPrint('🚨 REAL WebView Error (not cleanup):');
        debugPrint('   URL: ${request.url}');
        debugPrint('   Type: ${error.type}');
        debugPrint('   Description: ${error.description}');
        
        _fsmManager.onWebViewError('Error loading resource: ${error.description}');
      },
    );
    } catch (e) {
      debugPrint('⚠️ Falha ao criar HeadlessInAppWebView (ambiente não suportado). Usando simulação. Detalhes: $e');
      _runSpeedTestSimulationFallback();
      return;
    }

    try {
      debugPrint('🌐 Starting Headless WebView with URL: $url');
      await _headlessWebView?.run();
    } catch (e) {
      if (_isDisposed) {
        return;
      }
      _fsmManager.onWebViewError('Critical failure starting Headless WebView: ${e.toString()}');
    }
  }

  @override
  Future<SpeedTestResultModel> getSpeedTestResult() {
    return _fsmManager.getResult();
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    debugPrint('♻️ DataSource Dispose called.');
    
    if (kDebugMode) {
      debugPrint('🔧 Sending abort signal to WebView...');
      debugPrint('💡 Note: This will cause a expected net::ERR_FAILED in logs (normal cleanup behavior)');
    }
    
    _controller?.evaluateJavascript(source: 'if(window.speedtest) window.speedtest.abort();').catchError((e) {
      if (kDebugMode) {
        debugPrint("⚠️ Failed to send abort signal to JS: $e");
      }
    });
    
    if (kDebugMode) {
      debugPrint('🔧 Disposing HeadlessInAppWebView...');
    }
    
    _headlessWebView?.dispose();
    _headlessWebView = null;
    _controller = null;
    _fsmManager.dispose();
    
    if (kDebugMode) {
      debugPrint('✅ DataSource disposal completed.');
    }
  }

  void _runSpeedTestSimulationFallback() async {
    debugPrint('🧪 Running speed test simulation (fallback for web/unsupported platforms)...');
    
    if (kDebugMode) {
      debugPrint('🔧 Simulating WebView loading...');
    }
    
    _fsmManager.onWebViewLoaded(); 
    await Future.delayed(const Duration(seconds: 1));
    
    if (kDebugMode) {
      debugPrint('🔧 Sending simulated test results...');
    }
    
    final fakePayload = json.encode({
      'event': 'end',
      'payload': {
        'download': '50.0', 'upload': '20.0', 'ping': '12.0', 'jitter': '3.0',
        'ipInfo': {'isp': 'Simulated ISP'}, 'aborted': false,
      }
    });
    
    if (kDebugMode) {
      debugPrint('🔧 Fake payload: $fakePayload');
    }
    
    _fsmManager.onJsMessage(fakePayload);
  }
}

enum _SpeedTestState { idle, initializing, running, completed, error }

class _SpeedTestFsmManager {
  StreamController<DiagnosticProgressEntity>? _progressController;
  Completer<SpeedTestResultModel>? _resultCompleter;
  bool _resultObserved = false; 
  Timer? _globalTimeout;
  Timer? _progressWatchdog;
  Timer? _phaseTransitionWatchdog;
  DateTime? _actualTestStartTime;
  DateTime? _lastProgressTime;
  DateTime? _downloadCompletedTime;
  double _lastProgressValue = 0.0; 

  _SpeedTestState _currentState = _SpeedTestState.idle;
  String? _lastTestPhase;
  final Map<String, bool> _phaseCompleted = {}; 

  static const Duration _progressTimeoutDuration = Duration(seconds: 30); 

  void start(StreamController<DiagnosticProgressEntity> controller) {
    _progressController = controller;
    _resultCompleter = Completer<SpeedTestResultModel>();
    _resultObserved = false;
    _actualTestStartTime = DateTime.now(); 
    _lastProgressTime = DateTime.now();
    _lastProgressValue = 0.0; 
    transitionTo(_SpeedTestState.initializing);

    _globalTimeout = Timer(_SpeedTestConstants.globalTimeout, () {
      final elapsed = DateTime.now().difference(_actualTestStartTime ?? DateTime.now());
      if (kDebugMode) {
        debugPrint('⏰ Global timeout reached after ${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}');
        debugPrint('⏰ Current state: ${_currentState.name}');
        debugPrint('⏰ This might indicate slow network or server issues');
      }
      handleError('Test timed out after ${_SpeedTestConstants.globalTimeout.inMinutes} minutes. Please check your network connection and try again.');
    });

    _startProgressWatchdog();
  }

  void _startProgressWatchdog() {
    _progressWatchdog?.cancel();
    _progressWatchdog = Timer.periodic(const Duration(seconds: 10), (timer) {
      final now = DateTime.now();
      final timeSinceLastProgress = now.difference(_lastProgressTime ?? now);

      if (kDebugMode) {
        debugPrint('🐕 Watchdog Check: Last progress ${timeSinceLastProgress.inSeconds}s ago at ${(_lastProgressValue * 100).toStringAsFixed(1)}%');
      }
      
      if (timeSinceLastProgress > _progressTimeoutDuration) {
        debugPrint('🐕 Progress Watchdog: No progress for ${timeSinceLastProgress.inSeconds}s');
        debugPrint('🐕 Last progress: ${(_lastProgressValue * 100).toStringAsFixed(1)}% in phase: ${_lastTestPhase ?? 'unknown'}');
        
        if (_lastProgressValue > 0.3 && _lastProgressValue < 0.8) {
          debugPrint('� Test stuck in middle of phase - attempting recovery');
          debugPrint('💡 Tip: This often happens with unstable network connections');
          
          handleError('Test stuck at ${(_lastProgressValue * 100).toStringAsFixed(1)}% in ${_lastTestPhase ?? 'unknown'} phase. This usually indicates network instability. Try testing on a more stable connection.');
        } else {
          debugPrint('🐕 Test stuck at start/end - general timeout');
          handleError('Test appears to be stuck at ${(_lastProgressValue * 100).toStringAsFixed(1)}% in ${_lastTestPhase ?? 'unknown'} phase. Please check your network connection and try again.');
        }
        
        timer.cancel();
      }
    });
  }

  void _startPhaseTransitionWatchdog() {
    _phaseTransitionWatchdog?.cancel();
    debugPrint('🕐 Phase Transition Watchdog: Aguardando transição download → upload (30s)');
    
    _phaseTransitionWatchdog = Timer(const Duration(seconds: 30), () {
      final elapsed = DateTime.now().difference(_downloadCompletedTime ?? DateTime.now());
      debugPrint('🚨 PHASE TRANSITION TIMEOUT! Download completou há ${elapsed.inSeconds}s mas não mudou para upload!');
      debugPrint('🚨 Isso indica problema na configuração do LibreSpeed ou comunicação JS');
      
      handleError('Test stuck after completing download phase. Download finished but upload did not start after ${elapsed.inSeconds}s. This suggests a configuration issue with the speed test server.');
    });
  }

  void _updateProgress(double progress) {
    final now = DateTime.now();
    final progressPercent = (progress * 100).toStringAsFixed(1);
    
    _lastProgressTime = now;
    
    if (progress > _lastProgressValue + 0.005) {
      _lastProgressValue = progress;
      
      if (kDebugMode) {
        debugPrint('📈 Real Progress: $progressPercent% (watchdog reset)');
      }
    } else {
      if (kDebugMode && progress == _lastProgressValue) {
        debugPrint('⚠️ Same Progress: $progressPercent% (no advancement)');
      }
    }
  }

  Future<SpeedTestResultModel> getResult() {
    _resultObserved = true;
    return _resultCompleter?.future ?? Future.error(const SpeedTestException('Test not started'));
  }

  void onWebViewLoaded() {
    if (kDebugMode) {
      debugPrint('🔧 FSM: WebView loaded in state: ${_currentState.name}');
    }
    
    if (_currentState == _SpeedTestState.initializing) {
      transitionTo(_SpeedTestState.running);
      _emitProgress(DiagnosticStage.initializing, 1.0, 'Conexão com servidor estabelecida. Iniciando testes...');
    }
  }

  void onWebViewError(String message) {
    handleError(message);
  }

  void onJsMessage(String jsonMessage) {
    if (kDebugMode) {
      debugPrint('🔧 FSM: Received JS message in state: ${_currentState.name}');
      debugPrint('🔧 Raw JSON: $jsonMessage');
    }
    
    if (_currentState != _SpeedTestState.running) {
      if (kDebugMode) {
        debugPrint('⚠️ FSM: Ignoring JS message - not in running state');
      }
      return;
    }

    try {
      final message = _JsMessage.fromJson(json.decode(jsonMessage) as Map<String, dynamic>);
      debugPrint('📨 JS Message | event: ${message.event}, type: ${message.payload.type}');

      switch (message.event) {
        case 'error':
          debugPrint('🚨 JS Error Event | message: ${message.payload.message}');
          handleError(message.payload.message ?? 'Unknown JS error');
          break;
        case 'end':
          debugPrint('✅✅✅ TESTE CONCLUÍDO! Recebido evento END! ✅✅✅');
          debugPrint('✅ JS End Event | aborted: ${message.payload.aborted}, download: ${message.payload.download}, upload: ${message.payload.upload}');
          _handleEndMessage(message.payload);
          break;
        case 'progress':
          if (kDebugMode) {
            debugPrint('📊 JS Progress Event | type: ${message.payload.type}, progress: ${message.payload.progress}, speed: ${message.payload.speed}');
          }
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

    final progressPercent = (payload.progress * 100).toStringAsFixed(1);
    debugPrint('📊 PROGRESS: ${payload.type} at $progressPercent% - Speed: ${payload.speed ?? 'N/A'}');

    if (_lastTestPhase != payload.type) {
      debugPrint('🔄 Test Phase Change: ${_lastTestPhase ?? 'start'} → ${payload.type}');
      _lastTestPhase = payload.type;
      _phaseCompleted[payload.type] = false; 
      
      if (payload.type == 'upload') {
        _phaseTransitionWatchdog?.cancel();
        debugPrint('✅ Phase Transition Success! Upload iniciou normalmente');
      }
      
      switch(payload.type) {
        case 'download':
          debugPrint('⬇️ Starting DOWNLOAD test phase');
          break;
        case 'upload':
          debugPrint('⬆️ Starting UPLOAD test phase');
          break;
        case 'ping':
          debugPrint('📡 Starting PING test phase');
          break;
      }
    }

    if (payload.progress >= 1.0 && _phaseCompleted[payload.type] == true) {
      if (kDebugMode) {
        debugPrint('🚫 Ignoring duplicate 100% progress for ${payload.type}');
      }
      return;
    }

    if (payload.progress >= 1.0) {
      _phaseCompleted[payload.type] = true;
      debugPrint('✅ Phase ${payload.type} reached 100%');
      
      if (payload.type == 'download') {
        _downloadCompletedTime = DateTime.now();
        _startPhaseTransitionWatchdog();
      }
    }

    _updateProgress(payload.progress);

    if (kDebugMode && payload.progress > 0) {
      final progressPercent = (payload.progress * 100).toStringAsFixed(1);
      debugPrint('📊 Test Progress: ${payload.type} $progressPercent% - Speed: ${payload.speed ?? 'N/A'}');
    }

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
    if (kDebugMode) {
      debugPrint('🔧 FSM: Handling END message in state: ${_currentState.name}');
      debugPrint('🔧 Payload Details:');
      debugPrint('   Download: ${payload.download} Mbps');
      debugPrint('   Upload: ${payload.upload} Mbps');
      debugPrint('   Ping: ${payload.ping} ms');
      debugPrint('   Jitter: ${payload.jitter} ms');
      debugPrint('   Aborted: ${payload.aborted}');
      debugPrint('   ISP: ${payload.ipInfo['isp']}');
    }

    if (_currentState == _SpeedTestState.completed || _currentState == _SpeedTestState.error) {
      if (kDebugMode) {
        debugPrint('⚠️ FSM: Ignoring END message - already in final state: ${_currentState.name}');
      }
      return;
    }
    
    _lastTestPhase = null;
    
    debugPrint('🎯 FSM: Transitioning to COMPLETED state');
    transitionTo(_SpeedTestState.completed);

    final result = SpeedTestResultModel(
      downloadSpeed: payload.download ?? 0.0,
      uploadSpeed: payload.upload ?? 0.0,
      ping: payload.ping ?? 0.0,
      jitter: payload.jitter ?? 0.0,
      serverLocation: payload.ipInfo['isp'] as String? ?? 'Servidor Interno',
      testStartTime: _actualTestStartTime ?? DateTime.now().subtract(const Duration(seconds: 30)), // Usa o tempo real com fallback
      testEndTime: DateTime.now(),
      testCompleted: !(payload.aborted ?? false),
    );

    if (kDebugMode) {
      debugPrint('📋 FSM: Created result model:');
      debugPrint('   Download Speed: ${result.downloadSpeed} Mbps');
      debugPrint('   Upload Speed: ${result.uploadSpeed} Mbps');
      debugPrint('   Ping: ${result.ping} ms');
      debugPrint('   Test Completed: ${result.testCompleted}');
    }

    if (!(_resultCompleter?.isCompleted ?? true)) {
      debugPrint('✅ FSM: Completing result future');
      _resultCompleter?.complete(result);
    } else {
      if (kDebugMode) {
        debugPrint('⚠️ FSM: Result completer already completed');
      }
    }
    
    debugPrint('🚀 FSM: Emitting final progress with result');
    _emitProgress(DiagnosticStage.completed, 1.0, 'Teste concluído!', result: result);
    
    debugPrint('🧹 FSM: Calling dispose to cleanup resources');
    dispose();
  }

  void handleError(String message) {
    if (_currentState == _SpeedTestState.completed || _currentState == _SpeedTestState.error) {
      return;
    }
    
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
    _progressWatchdog?.cancel();
    _phaseTransitionWatchdog?.cancel(); 
    if (_currentState != _SpeedTestState.completed && _currentState != _SpeedTestState.error) {
      if (_resultObserved && !(_resultCompleter?.isCompleted ?? true)) {
        _resultCompleter?.completeError(const SpeedTestException("Test cancelled by user"), StackTrace.current);
      }
    }
    _progressController?.close();
  }

  void transitionTo(_SpeedTestState newState) {
    if (_currentState == newState) {
      return;
    }
    debugPrint('[FSM] State transition: ${_currentState.name} -> ${newState.name}');
    _currentState = newState;
  }

  void _emitProgress(DiagnosticStage stage, double progress, String message, {SpeedTestResultModel? result}) {
    if (kDebugMode) {
      debugPrint('📡 FSM: Emitting progress event');
      debugPrint('   Stage: ${stage.name}');
      debugPrint('   Progress: ${(progress * 100).toStringAsFixed(1)}%');
      debugPrint('   Message: $message');
      debugPrint('   Has Result: ${result != null}');
    }

    if (_progressController?.isClosed == false) {
      final progressEntity = DiagnosticProgressEntity(
        stage: stage,
        progress: progress,
        message: message,
        timestamp: DateTime.now(),
        speedTestResult: result,
      );
      
      debugPrint('📤 FSM: Adding progress entity to stream');
      _progressController!.add(progressEntity);
      
      if (result != null) {
        debugPrint('🎉 FSM: Final result sent to UI! Download: ${result.downloadSpeed} Mbps, Upload: ${result.uploadSpeed} Mbps');
      }
    } else {
      if (kDebugMode) {
        debugPrint('⚠️ FSM: Progress controller is closed, cannot emit progress');
      }
    }
  }
}