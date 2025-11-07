import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:maxt_diagnostic/features/home/presentation/cubit/home_cubit.dart';
import 'package:maxt_diagnostic/core/config/app_config.dart';
import 'package:maxt_diagnostic/core/di/injection_container.dart' as di;
import 'package:maxt_diagnostic/features/home/presentation/view/widgets/diagnostic_button.dart';
import 'package:maxt_diagnostic/features/home/presentation/view/widgets/network_info_card.dart';
import 'package:maxt_diagnostic/features/home/presentation/view/widgets/quick_tips_card.dart';
import 'package:maxt_diagnostic/features/home/presentation/view/widgets/rotating_info_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showBlockedStartSheet(
    BuildContext context, {
    required bool noConnection,
    required int? currentDbm,
    required int excellentThreshold,
  }) {
    Color qualityColor(SignalQuality q) {
      switch (q) {
        case SignalQuality.excellent:
          return const Color(0xFF16A34A);
        case SignalQuality.normal:
          return const Color(0xFFD97706);
        case SignalQuality.poor:
          return const Color(0xFFDC2626);
      }
    }

  final config = di.sl<AppConfig>();
    final quality = config.getSignalQuality(currentDbm);
    double progress;
    if (currentDbm == null) {
      progress = 0;
    } else {
      final min = config.signalNormalThresholdDbm.toDouble();
      final max = config.signalExcellentThresholdDbm.toDouble();
      progress = ((currentDbm - min) / (max - min)).clamp(0.0, 1.0);
    }
    final deficit =
        currentDbm == null ? null : (excellentThreshold - currentDbm);
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: <Widget>[
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Não é possível iniciar o teste',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (noConnection) ...[
                const Text(
                    'Conecte-se a uma rede Wi‑Fi para iniciar o diagnóstico.'),
              ] else ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: qualityColor(quality).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        config.qualityLabel(quality),
                        style: TextStyle(
                          color: qualityColor(quality),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                        'Sinal atual: ${currentDbm != null ? '$currentDbm dBm' : 'indisponível'}'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: qualityColor(quality),
                ),
                const SizedBox(height: 8),
                Text(
                    'Necessário: ≥ $excellentThreshold dBm (Excelente, mais próximo de 0).'),
                if (deficit != null && deficit > 0) ...[
                  Text('Faltam ${deficit.abs()} dB para atingir Excelente.'),
                ],
              ],
              const SizedBox(height: 12),
              const Text(
                'Para melhorar o sinal, siga as Dicas rápidas exibidas na tela.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Entendi'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeInitial) {
              context.read<HomeCubit>().fetchInitialInfo();
              return const Center(child: CircularProgressIndicator());
            }

            if (state is HomeLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is HomeError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Erro ao carregar: ${state.message}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<HomeCubit>().fetchInitialInfo(),
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is HomePermissionDenied) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          await context
                              .read<HomeCubit>()
                              .requestLocationPermission();
                        },
                        child: const Text('Conceder permissões'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is HomeLoaded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<HomeCubit>().startAutoRefresh();
              });
              final config = di.sl<AppConfig>();
              final noConnection =
                  state.networkInfo.connectionType.toLowerCase() == 'none';
              final canStart = !noConnection &&
                  config
                      .isSignalExcellent(state.networkInfo.wifiSignalStrength);
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 40, bottom: 24),
                    child: Column(
                      children: [
                        Text('MAX INTERNET',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Status da Rede',
                            style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          NetworkInfoCard(networkInfo: state.networkInfo),
                          const SizedBox(height: 16),
                          const QuickTipsCard(),
                          const SizedBox(height: 16),
                          const RotatingInfoCard(),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DiagnosticButton(
                        isEnabled: canStart,
                        onPressed: () {
                          context.go('/diagnostic');
                        },
                        onBlockedTap: () {
                          _showBlockedStartSheet(
                            context,
                            noConnection: noConnection,
                            currentDbm: state.networkInfo.wifiSignalStrength,
                            excellentThreshold:
                                config.signalExcellentThresholdDbm,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            }

            return const Center(child: Text('Estado não reconhecido.'));
          },
        ),
      ),
    );
  }
}
