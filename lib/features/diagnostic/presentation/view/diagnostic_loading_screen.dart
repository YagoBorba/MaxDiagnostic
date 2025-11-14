import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:maxt_diagnostic/core/di/injection_container.dart';
import 'package:maxt_diagnostic/features/diagnostic/presentation/cubit/diagnostic_cubit.dart';
import 'package:maxt_diagnostic/features/diagnostic/presentation/view/widgets/pulsing_wifi_icon.dart';

class DiagnosticLoadingScreen extends StatelessWidget {
  const DiagnosticLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DiagnosticCubit>(),
      child: const _DiagnosticLoadingView(),
    );
  }
}

class _DiagnosticLoadingView extends StatelessWidget {
  const _DiagnosticLoadingView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<DiagnosticCubit, DiagnosticState>(
      listener: (context, state) {
        if (state.finalResults != null &&
            state.globalStatus == GlobalTestStatus.complete) {
          
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (context.mounted) {
              context.go('/results', extra: state.finalResults);
            }
          });
        }
        
        if (state.globalStatus == GlobalTestStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Erro ao realizar diagnóstico'),
              backgroundColor: Colors.red.shade600,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: const Scaffold(
        body: SafeArea(
          child: _DiagnosticContent(),
        ),
      ),
    );
  }
}

class _DiagnosticContent extends StatefulWidget {
  const _DiagnosticContent();

  @override
  State<_DiagnosticContent> createState() => _DiagnosticContentState();
}

class _DiagnosticContentState extends State<_DiagnosticContent> {
  Timer? _timer;
  int _messageIndex = 0;
  bool _hasTestStarted = false;

  static const _statusMessages = [
    'Inicializando diagnóstico...',
    'Analisando sua conexão...',
    'Verificando informações do dispositivo...',
    'Inspecionando a rede local...',
    'Conectando ao servidor de teste...',
    'Executando teste de velocidade...',
    'Analisando estabilidade da conexão...',
    'Compilando resultados...',
  ];

  @override
  void initState() {
    super.initState();
    _startMessageTimer();
  }

  void _startMessageTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      var currentState = context.read<DiagnosticCubit>().state;

      if (!_hasTestStarted && mounted) {
        _hasTestStarted = true;
        context.read<DiagnosticCubit>().startTest();
        currentState = context.read<DiagnosticCubit>().state;
      }

      if (currentState.globalStatus != GlobalTestStatus.running) {
        timer.cancel();
        return;
      }

      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _statusMessages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getDisplayMessage(DiagnosticState state) {
    if (state.globalStatus == GlobalTestStatus.error) {
      _timer?.cancel();
      return state.errorMessage ?? 'Ocorreu um erro';
    }
    if (state.globalStatus == GlobalTestStatus.complete) {
      _timer?.cancel();
      return 'Diagnóstico concluído!';
    }

    if (!_hasTestStarted || state.globalStatus == GlobalTestStatus.pending) {
      return 'Inicializando diagnóstico...';
    }
    
    return _statusMessages[_messageIndex];
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DiagnosticCubit>().state;
    final progress = state.overallProgress;
    final isRunning = state.globalStatus == GlobalTestStatus.running;
    
    final statusMessage = _getDisplayMessage(state);

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 40, bottom: 24),
          child: Text(
            'MAX INTERNET',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              const Text(
                'Diagnóstico de Rede',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: Text(
                  statusMessage,
                  key: ValueKey<String>(statusMessage),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        const Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RepaintBoundary(
                  child: PulsingWifiIcon(),
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Text(
                'Progresso do diagnóstico',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 8,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(
                      begin: 0,
                      end: progress / 100,
                    ),
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: const Color(0xFFE2E8F0), 
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF3B82F6),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        if (isRunning) const _BottomAlert(),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _BottomAlert extends StatelessWidget {
  const _BottomAlert();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7).withValues(alpha: 0.3),
          border: Border.all(
            color: const Color(0xFFFEF3C7).withValues(alpha: 0.6),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 20,
              color: Color(0xFF92400E),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Não feche o aplicativo durante o diagnóstico',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF92400E),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}