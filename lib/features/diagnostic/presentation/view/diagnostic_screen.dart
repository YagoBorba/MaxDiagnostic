import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:maxt_diagnostic/core/di/injection_container.dart';
import 'package:maxt_diagnostic/data/datasources/speed_test_remote_datasource.dart';
import 'package:maxt_diagnostic/features/diagnostic/presentation/cubit/diagnostic_cubit.dart';
import 'package:maxt_diagnostic/features/diagnostic/presentation/view/widgets/test_item_card.dart';

class DiagnosticScreen extends StatelessWidget {
  const DiagnosticScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DiagnosticCubit>()..startTest(),
      child: const _DiagnosticView(),
    );
  }
}

class _DiagnosticView extends StatelessWidget {
  const _DiagnosticView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DiagnosticCubit>().state;
    final bool isTestRunning = state.globalStatus == GlobalTestStatus.running;

    return BlocListener<DiagnosticCubit, DiagnosticState>(
      listener: (context, state) {
        if (state.finalResults != null &&
            state.globalStatus == GlobalTestStatus.complete) {
          context.go('/results', extra: state.finalResults);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black12,
          leading: IconButton(
            icon: Icon(
              LucideIcons.arrowLeft,
              color: isTestRunning ? Colors.grey : const Color(0xFF1E293B),
            ),
            onPressed: isTestRunning ? null : () => context.pop(),
          ),
          title: const Text('MAX INTERNET',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const _SpeedTestWebViewHost(),
              const Text(
                'Diagnóstico de Rede',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Analisando sua conexão MAX Internet',
                style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              _MainProgressCard(
                progress: state.overallProgress,
                status: state.globalStatus,
              ),
              const SizedBox(height: 24),
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: state.tests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final test = state.tests.values.elementAt(index);
                  return TestItemCard(test: test);
                },
              ),
              const SizedBox(height: 16),
              if (isTestRunning) const _WarningCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeedTestWebViewHost extends StatelessWidget {
  const _SpeedTestWebViewHost();

  @override
  Widget build(BuildContext context) {
    final ds = sl<SpeedTestRemoteDataSource>();
    return Offstage(
      offstage: true,
      child: SizedBox(width: 1, height: 1, child: ds.widget),
    );
  }
}

class _MainProgressCard extends StatelessWidget {
  final double progress;
  final GlobalTestStatus status;

  const _MainProgressCard({required this.progress, required this.status});

  String get _statusText {
    switch (status) {
      case GlobalTestStatus.running:
        return 'Em Progresso';
      case GlobalTestStatus.complete:
        return 'Concluído';
      case GlobalTestStatus.error:
        return 'Falhou';
      case GlobalTestStatus.pending:
        return 'Aguardando';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4D89FF).withAlpha(26),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            '${progress.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4D89FF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _statusText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4D89FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(LucideIcons.zap, color: Color(0xFF92400E)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Não feche o aplicativo durante o diagnóstico',
              style: TextStyle(fontSize: 14, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }
}
