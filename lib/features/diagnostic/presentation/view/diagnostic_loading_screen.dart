import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:maxt_diagnostic/core/di/injection_container.dart';
import 'package:maxt_diagnostic/features/diagnostic/presentation/cubit/diagnostic_cubit.dart';
import 'package:maxt_diagnostic/features/diagnostic/presentation/view/widgets/pulsing_wifi_icon.dart';
import 'package:maxt_diagnostic/features/diagnostic/presentation/view/widgets/animated_time_remaining.dart';

class DiagnosticLoadingScreen extends StatelessWidget {
  const DiagnosticLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DiagnosticCubit>()..startTest(),
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
          context.go('/results', extra: state.finalResults);
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
        backgroundColor: Color(0xFFFAFAFA), 
        body: SafeArea(
          child: _DiagnosticContent(),
        ),
      ),
    );
  }
}

class _DiagnosticContent extends StatelessWidget {
  const _DiagnosticContent();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DiagnosticCubit>().state;
    final progress = state.overallProgress;
    final isRunning = state.globalStatus == GlobalTestStatus.running;
    
    const totalTime = 30;
    final timeRemainingExact = (totalTime * (100 - progress)) / 100;
    final timeRemaining = timeRemainingExact.floor().clamp(0, totalTime);

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
        
        const Padding(
          padding: EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              Text(
                'Diagnóstico de Rede',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Analisando sua conexão',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progresso do diagnóstico',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (isRunning)
                    AnimatedTimeRemaining(seconds: timeRemaining),
                ],
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
