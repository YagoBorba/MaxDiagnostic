import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maxt_diagnostic/core/di/injection_container.dart' as di;
import 'package:maxt_diagnostic/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:maxt_diagnostic/features/known_networks/domain/entities/known_network.dart';
import 'package:maxt_diagnostic/features/known_networks/presentation/cubit/known_network_cubit.dart';

class NetworkListScreen extends StatelessWidget {
  const NetworkListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<KnownNetworkCubit>()..watchNetworks(),
      child: const _NetworkListView(),
    );
  }
}

class _NetworkListView extends StatelessWidget {
  const _NetworkListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Redes Wi-Fi'),
      ),
      body: BlocConsumer<KnownNetworkCubit, KnownNetworkState>(
        listener: (context, state) {
          if (state.status == NetworkStatus.error && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          if (state.status == NetworkStatus.loading ||
              state.status == NetworkStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.networks.isEmpty) {
            return const _EmptyNetworksView();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: state.networks.length,
            itemBuilder: (context, index) {
              final network = state.networks[index];
              return Dismissible(
                key: ValueKey(network.remoteId ?? network.bssid),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  return await _confirmDeletion(context, network);
                },
                onDismissed: (_) {
                  final id = network.remoteId;
                  if (id != null) {
                    context.read<KnownNetworkCubit>().delete(id);
                  }
                },
                child: _KnownNetworkTile(network: network),
              );
            },
            separatorBuilder: (context, _) => const SizedBox(height: 8),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNetworkDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
    );
  }

  Future<bool?> _confirmDeletion(BuildContext context, KnownNetwork network) {
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
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddNetworkDialog(BuildContext context) async {
    final authState = context.read<AuthCubit>().state;
    final user = authState.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para salvar redes.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final ssidController = TextEditingController();
    final bssidController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Adicionar rede conhecida'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Apelido'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe um apelido';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: ssidController,
                    decoration: const InputDecoration(labelText: 'SSID'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o SSID';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: bssidController,
                    decoration: const InputDecoration(labelText: 'BSSID'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o BSSID';
                      }
                      return null;
                    },
                  ),
                ],
              ),
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
                final network = KnownNetwork(
                  ownerUid: user.uid,
                  name: nameController.text.trim(),
                  ssid: ssidController.text.trim(),
                  bssid: bssidController.text.trim(),
                  updatedAt: DateTime.now(),
                );
                final cubit = context.read<KnownNetworkCubit>();
                await cubit.save(network);
                if (!dialogContext.mounted || !context.mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rede salva com sucesso.')),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}

class _KnownNetworkTile extends StatelessWidget {
  const _KnownNetworkTile({required this.network});

  final KnownNetwork network;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
      title: Text(network.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('SSID: ${network.ssid}\nBSSID: ${network.bssid}'),
      isThreeLine: true,
      trailing: Text(
        _formatDate(network.updatedAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

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
