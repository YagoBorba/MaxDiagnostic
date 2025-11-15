// lib/features/home/presentation/view/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:maxt_diagnostic/core/config/app_config.dart';
import 'package:maxt_diagnostic/core/di/injection_container.dart' as di;
import 'package:maxt_diagnostic/core/theme/brand_theme_colors.dart';
import 'package:maxt_diagnostic/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:maxt_diagnostic/features/home/presentation/cubit/home_cubit.dart';
import 'package:maxt_diagnostic/features/home/presentation/view/widgets/diagnostic_button.dart';
import 'package:maxt_diagnostic/features/home/presentation/view/widgets/network_info_card.dart';
import 'package:maxt_diagnostic/features/home/presentation/view/widgets/quick_tips_card.dart';
import 'package:maxt_diagnostic/features/home/presentation/view/widgets/rotating_info_card.dart';
import 'package:maxt_diagnostic/features/known_networks/domain/entities/known_network.dart';
import 'package:maxt_diagnostic/features/known_networks/presentation/cubit/known_network_cubit.dart';

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

    final double progress;
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
                    'Conecte-se a uma rede Wi-Fi para iniciar o diagnóstico.'),
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
                      'Sinal atual: ${currentDbm != null ? '$currentDbm dBm' : 'indisponível'}',
                    ),
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
                  'Necessário: ≥ $excellentThreshold dBm (Excelente, mais próximo de 0).',
                ),
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
        leading: _buildPopupMenu(context),
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
                padding: const EdgeInsets.all(24),
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
                padding: const EdgeInsets.all(24),
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
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  child: Center(
                    child: Text(
                      'Status da Rede',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.9),
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

  PopupMenuButton<_HomeMenu> _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<_HomeMenu>(
      icon: const Icon(LucideIcons.menu),
      onSelected: (item) {
        switch (item) {
          case _HomeMenu.networks:
            _showNetworkListDialog(context);
            break;
          case _HomeMenu.logout:
            context.read<AuthCubit>().signOut();
            break;
        }
      },
      itemBuilder: (menuContext) => const <PopupMenuEntry<_HomeMenu>>[
        PopupMenuItem<_HomeMenu>(
          value: _HomeMenu.networks,
          child: ListTile(
            leading: Icon(LucideIcons.wifi),
            title: Text('Minhas Redes'),
          ),
        ),
        PopupMenuItem<_HomeMenu>(
          value: _HomeMenu.logout,
          child: ListTile(
            leading: Icon(LucideIcons.logOut),
            title: Text('Sair'),
          ),
        ),
      ],
    );
  }

  Future<void> _showNetworkListDialog(BuildContext context) async {
    final homeCubit = context.read<HomeCubit>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final listDialogContext = dialogContext;
        return BlocProvider(
          create: (_) => di.sl<KnownNetworkCubit>()..watchNetworks(),
          child: BlocConsumer<KnownNetworkCubit, KnownNetworkState>(
            listener: (listContext, listState) {
              if (listState.status == NetworkStatus.error &&
                  listState.error != null &&
                  context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(listState.error!)),
                );
              }
            },
            builder: (listContext, listState) {
              return AlertDialog(
                title: const Text('Minhas Redes Wi-Fi'),
                content: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: SizedBox(
                    key: ValueKey(listState.status),
                    width: double.maxFinite,
                    child: _buildNetworkListContent(
                      context,
                      listContext,
                      listState,
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(listDialogContext).pop(),
                    child: const Text('Fechar'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Atual'),
                    onPressed: () => _showAddNetworkDialog(
                      rootContext: context,
                      cubitContext: listContext,
                      listDialogContext: listDialogContext,
                      homeCubit: homeCubit,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNetworkListContent(
    BuildContext rootContext,
    BuildContext cubitContext,
    KnownNetworkState state,
  ) {
    if (state.status == NetworkStatus.initial ||
        state.status == NetworkStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == NetworkStatus.error && state.networks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(state.error ?? 'Erro ao carregar redes.'),
        ),
      );
    }

    if (state.networks.isEmpty) {
      return const _EmptyNetworksView();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: state.networks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (itemContext, index) {
        final network = state.networks[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(network.name),
            subtitle: Text('SSID: ${network.ssid}\nBSSID: ${network.bssid}'),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Remover rede',
              onPressed: network.remoteId == null
                  ? null
                  : () async {
                      final cubit = cubitContext.read<KnownNetworkCubit>();
                      final shouldDelete =
                          await _confirmNetworkDeletion(cubitContext, network);
                      if (shouldDelete != true) {
                        return;
                      }

                      if (!cubitContext.mounted) return;
                      await cubit.delete(network.remoteId!);

                      if (!rootContext.mounted) return;
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(
                          content: Text('Rede "${network.name}" removida.'),
                        ),
                      );
                    },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddNetworkDialog({
    required BuildContext rootContext,
    required BuildContext cubitContext,
    required BuildContext listDialogContext,
    required HomeCubit homeCubit,
  }) async {
    if (!rootContext.mounted) return;

    final homeState = homeCubit.state;
    if (homeState is! HomeLoaded) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(
          content: Text('Informações da rede atual não disponíveis.'),
        ),
      );
      return;
    }

    final networkInfo = homeState.networkInfo;
    if (networkInfo.wifiBSSID == null || networkInfo.wifiName == null) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(
          content: Text('Não conectado a uma rede Wi-Fi válida.'),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();

    await showDialog<void>(
      context: rootContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Adicionar Rede Atual'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rede (SSID): ${networkInfo.wifiName}'),
                Text('BSSID: ${networkInfo.wifiBSSID}'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Apelido (ex: Casa) *',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Obrigatório';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final authState = rootContext.read<AuthCubit>().state;
                final user = authState.user;
                if (user == null) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(
                      content: Text('Faça login para salvar redes.'),
                    ),
                  );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  return;
                }

                final cubit = cubitContext.read<KnownNetworkCubit>();

                final network = KnownNetwork(
                  ownerUid: user.uid,
                  name: nameController.text.trim(),
                  ssid: networkInfo.wifiName!,
                  bssid: networkInfo.wifiBSSID!,
                  updatedAt: DateTime.now(),
                );

                await cubit.save(network);

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }

                if (rootContext.mounted) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(content: Text('Rede salva com sucesso.')),
                  );
                }

                if (listDialogContext.mounted) {
                  Navigator.of(listDialogContext).pop();
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _confirmNetworkDeletion(
    BuildContext context,
    KnownNetwork network,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remover rede'),
          content: Text('Deseja remover "${network.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remover', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

enum _HomeMenu { networks, logout }

class _EmptyNetworksView extends StatelessWidget {
  const _EmptyNetworksView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma rede salva por enquanto. Adicione uma para receber alertas personalizados.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}