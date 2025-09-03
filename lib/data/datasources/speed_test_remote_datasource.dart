import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maxt_diagnostic/core/config/app_config.dart';
import 'package:maxt_diagnostic/core/error/exceptions.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';
import 'package:maxt_diagnostic/data/models/final_results_model.dart'; 
import 'package:webview_flutter/webview_flutter.dart';

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
  StreamController<DiagnosticProgressModel>? _progressController;
  Completer<SpeedTestResultModel>? _resultCompleter;

  SpeedTestRemoteDataSourceImpl({required this.config}) {
    if (_supportsEmbeddedWebView) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000));
    }
  }

  @override
  Stream<DiagnosticProgressModel> runSpeedTest() {
    _progressController = StreamController<DiagnosticProgressModel>.broadcast();
    _resultCompleter = Completer<SpeedTestResultModel>();

    if (kIsWeb || !_supportsEmbeddedWebView) {
      _runSpeedTestSimulationFallback();
    } else {
      _initializeAndRunWebViewTest();
    }

    Timer(const Duration(minutes: 2), () {
      if (_resultCompleter != null && !_resultCompleter!.isCompleted) {
        _handleError('Teste excedeu o tempo limite (2 minutos)');
      }
    });

    return _progressController!.stream;
  }

  @override
  Future<SpeedTestResultModel> getSpeedTestResult() {
    return _resultCompleter?.future ?? Future.error(const SpeedTestException('Teste não iniciado'));
  }

  void _initializeAndRunWebViewTest() {
    final controller = _controller;
    if (controller == null) {
      _handleError('WebView não suportada nesta plataforma.');
      return;
    }

    final navigationDelegate = NavigationDelegate(
      onPageFinished: (String url) async {
        debugPrint('✅ Página carregada: $url. Comandando o runner...');
        try {
          await controller.runJavaScript('window.initialize()');
          debugPrint('✅ Dart: Comando initialize() executado no JS.');

          await controller.runJavaScript('window.startTest()');
          debugPrint('✅ Dart: Comando startTest() executado no JS.');
        } catch (e) {
          _handleError('Falha ao executar comandos de inicialização no JS: ${e.toString()}');
        }
      },
      onWebResourceError: (WebResourceError error) {
        _handleError('Erro ao carregar a página da WebView: ${error.description}');
      },
    );

    controller
      ..setNavigationDelegate(navigationDelegate)
      ..addJavaScriptChannel(
        'FlutterChannel', 
        onMessageReceived: (JavaScriptMessage message) {
          _handleJavaScriptMessage(message.message);
        },
      ).then((_) {
         debugPrint('🌐 Canal configurado. Carregando URL: ${config.speedTestUrl}');
         controller.loadRequest(Uri.parse(config.speedTestUrl));
      }).catchError((e) {
        _handleError('Falha crítica ao configurar o canal de comunicação: ${e.toString()}');
      });
  }

  void _handleJavaScriptMessage(String message) {
    try {
      debugPrint('📨 Mensagem do JS: $message');
      final data = json.decode(message) as Map<String, dynamic>;
      final event = data['event'] as String?;
      final payload = data['payload'] as Map<String, dynamic>? ?? {};

      switch (event) {
        case 'progress':
          _handleProgressMessage(payload);
          break;
        case 'end':
          _handleResultMessage(payload);
          break;
        case 'error':
          _handleError(payload['message'] as String? ?? 'Erro desconhecido no JavaScript');
          break;
        case 'status':
            debugPrint('ℹ️ Mensagem de status da WebView: ${payload['message']}');
            break;
        default:
          debugPrint('⚠️ Evento JS desconhecido recebido: $event');
      }
    } catch (e) {
      _handleError('Falha ao decodificar mensagem da WebView: ${e.toString()}');
    }
  }

  void _handleProgressMessage(Map<String, dynamic> payload) {
    final type = payload['type'] as String? ?? '';
    if (type == 'progress') return;

    final stage = _mapStringToStage(type);
    final progress = (payload['progress'] as num?)?.toDouble() ?? 0.0;
    final speed = payload['speed'];
    String message = '';

    switch (stage) {
      case DiagnosticStage.runningDownloadTest:
        if (speed != null && speed.toString().isNotEmpty) {
          message = 'Download: $speed Mbps';
        } else {
          message = 'Aguardando início do download...';
        }
        break;
      case DiagnosticStage.runningUploadTest:
        if (speed != null && speed.toString().isNotEmpty) {
          message = 'Upload: $speed Mbps';
        } else {
          message = 'Aguardando início do upload...';
        }
        break;
      case DiagnosticStage.runningPingTest:
        if (speed != null && speed.toString().isNotEmpty) {
          message = 'Ping: $speed ms';
        } else {
          message = 'Aguardando início do ping...';
        }
        break;
      default:
        message = 'Executando teste...';
    }
    _emitProgress(stage, progress, message);
  }

  void _handleResultMessage(Map<String, dynamic> payload) {
    if (_resultCompleter?.isCompleted ?? true) return; 
    try {
      final ipInfo = payload['ipInfo'] as Map<String, dynamic>? ?? {};
      final result = SpeedTestResultModel(
        downloadSpeed: (payload['download'] as num?)?.toDouble() ?? 0.0,
        uploadSpeed: (payload['upload'] as num?)?.toDouble() ?? 0.0,
        ping: (payload['ping'] as num?)?.toDouble() ?? 0.0,
        jitter: (payload['jitter'] as num?)?.toDouble() ?? 0.0,
        serverLocation: ipInfo['isp'] as String? ?? 'Servidor Interno',
        testStartTime: DateTime.now().subtract(const Duration(seconds: 30)), 
        testEndTime: DateTime.now(),
        testCompleted: !(payload['aborted'] as bool? ?? false),
      );
      _emitProgress(DiagnosticStage.completed, 1.0, 'Teste concluído!');
      _resultCompleter!.complete(result);
    } catch (e) {
      _handleError('Erro ao processar objeto de resultado final: ${e.toString()}');
    } finally {
      _progressController?.close();
    }
  }

  void _handleError(String errorMessage) {
    if (_resultCompleter?.isCompleted ?? true) return;

    _emitProgress(DiagnosticStage.error, 0.0, errorMessage);
    
    final errorResult = SpeedTestResultModel(
        downloadSpeed: 0, uploadSpeed: 0, ping: 0, jitter: 0, 
        serverLocation: 'Error', testStartTime: DateTime.now(), 
        testEndTime: DateTime.now(), testCompleted: false, 
        errorMessage: errorMessage);
    _resultCompleter!.complete(errorResult);
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
        case 'download': return DiagnosticStage.runningDownloadTest;
        case 'upload': return DiagnosticStage.runningUploadTest;
        case 'ping': return DiagnosticStage.runningPingTest;
        case 'starting': return DiagnosticStage.startingSpeedTest;
        case 'completed': return DiagnosticStage.completed;
        default: return DiagnosticStage.initializing;
      }
  }

  @override
  Widget get widget {
    if (kIsWeb || !_supportsEmbeddedWebView) {
      return const SizedBox.shrink();
    }
    return Offstage(
      offstage: true,
      child: WebViewWidget(controller: _controller!),
    );
  }

  @override
  void dispose() {
    _progressController?.close();
    _resultCompleter = null;
  }

  void _runSpeedTestSimulationFallback() async {
    debugPrint('🧪 Iniciando simulação de teste de velocidade (fallback sem WebView)...');
    final stages = <DiagnosticStage>[
      DiagnosticStage.startingSpeedTest,
      DiagnosticStage.runningDownloadTest,
      DiagnosticStage.runningUploadTest,
      DiagnosticStage.runningPingTest,
    ];
    for (final s in stages) {
      for (int i = 1; i <= 5; i++) {
        await Future.delayed(const Duration(milliseconds: 120));
        _emitProgress(s, i / 5.0, 'Simulando ${s.name}');
      }
    }
    await Future.delayed(const Duration(milliseconds: 200));
    _handleResultMessage({
      'download': 50.0,
      'upload': 20.0,
      'ping': 12.0,
      'jitter': 3.0,
      'ipInfo': {'isp': 'Simulado'},
      'aborted': false,
    });
  }
}