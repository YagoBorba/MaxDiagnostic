import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:maxt_diagnostic/features/home/presentation/cubit/home_cubit.dart';
import 'package:maxt_diagnostic/core/config/app_config.dart';
import 'package:maxt_diagnostic/core/di/injection_container.dart' as di;
import 'package:maxt_diagnostic/core/theme/brand_theme_colors.dart';
import 'package:maxt_diagnostic/features/home/presentation/view/widgets/diagnostic_button.dart';
import 'package:maxt_diagnostic/features/home/presentation/view/widgets/network_info_card.dart';
import 'package:maxt_diagnostic/features/home/presentation/view/widgets/quick_tips_card.dart';
import 'package:maxt_diagnostic/features/home/presentation/view/widgets/rotating_info_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showBlockedStartSheet(
    BuildContext context, {
    required bool noConnection,
    required bool isServerUnreachable,
    required int? currentDbm,
    required int excellentThreshold,
  }) {
    final theme = Theme.of(context);
    final brandColors = theme.extension<BrandThemeColors>()!;

    final config = di.sl<AppConfig>();
    final quality = config.getSignalQuality(currentDbm);
    final Color signalColor;
    switch (quality) {
      case SignalQuality.excellent:
        signalColor = brandColors.signalExcellent;
        break;
      case SignalQuality.normal:
        signalColor = brandColors.signalNormal;
        break;
      case SignalQuality.poor:
        signalColor = brandColors.signalPoor;
        break;
    }
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
              ] else if (isServerUnreachable) ...[
                const Text(
                  'Não foi possível conectar ao servidor de diagnóstico. Por favor, verifique se está conectado à rede apropriada e tente novamente.',
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: signalColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        config.qualityLabel(quality),
                        style: TextStyle(
                          color: signalColor,
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
                  color: signalColor,
                ),
                const SizedBox(height: 8),
                Text(
                    'Necessário: ≥ $excellentThreshold dBm (Excelente, mais próximo de 0).'),
                if (deficit != null && deficit > 0) ...[
                  Text('Faltam ${deficit.abs()} dB para atingir Excelente.'),
                ],
              ],
              const SizedBox(height: 12),
              if (!isServerUnreachable) ...[
                const Text(
                  'Para melhorar o sinal, siga as Dicas rápidas exibidas na tela.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
              ],
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MAX DIAGNÓSTICO'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: BlocBuilder<HomeCubit, HomeState>(
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

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                  child: Center(
                    child: Text(
                      'Status da Rede',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.9,
                        ),
                      ),
                    ),
                  ),
                ),
                NetworkInfoCard(networkInfo: state.networkInfo),
                const SizedBox(height: 24),
                const QuickTipsCard(),
                const SizedBox(height: 24),
                const RotatingInfoCard(),
                const SizedBox(height: 32),
              ],
            );
          }

          return const Center(child: Text('Estado não reconhecido.'));
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is! HomeLoaded) {
              return DiagnosticButton(
                isEnabled: false,
                onPressed: () => context.go('/diagnostic'),
              );
            }

            final config = di.sl<AppConfig>();
            final noConnection =
                state.networkInfo.connectionType.toLowerCase() == 'none';
            final isServerReachable = state.isSpeedTestServerReachable;
            final canStart = !noConnection &&
                isServerReachable &&
                config.isSignalExcellent(state.networkInfo.wifiSignalStrength);

            return DiagnosticButton(
              isEnabled: canStart,
              onPressed: () => context.go('/diagnostic'),
              onBlockedTap: () {
                _showBlockedStartSheet(
                  context,
                  noConnection: noConnection,
                  isServerUnreachable: !isServerReachable,
                  currentDbm: state.networkInfo.wifiSignalStrength,
                  excellentThreshold: config.signalExcellentThresholdDbm,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
