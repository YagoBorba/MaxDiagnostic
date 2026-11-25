import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:maxt_diagnostic/core/config/app_config.dart';
import 'package:maxt_diagnostic/core/di/injection_container.dart' as di;
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';
import 'package:maxt_diagnostic/features/home/presentation/view/widgets/signal_strength_text.dart';

class NetworkInfoCard extends StatelessWidget {
  final NetworkInfoEntity networkInfo;

  const NetworkInfoCard({super.key, required this.networkInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final config = di.sl<AppConfig>();

    final isConnected = networkInfo.connectionType.toLowerCase() != 'none';
    final titleText = () {
      if (!isConnected) return 'Sem conexão';
      if (networkInfo.connectionType.toLowerCase() == 'wifi') {
        return networkInfo.wifiName ?? 'WiFi';
      }
      return networkInfo.connectionType;
    }();
    final signalDbm = networkInfo.wifiSignalStrength;
    final frequency = networkInfo.wifiFrequency;
    final quality = config.getSignalQuality(signalDbm);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.wifi,
                  color: isConnected ? primaryColor : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  titleText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isConnected && signalDbm != null) ...[
              _InfoDetail(
                label: 'Sinal:',
                value: '$signalDbm dBm',
              ),
              const SizedBox(height: 6),
              _InfoDetail(
                label: 'Frequência:',
                value: frequency ?? '-',
              ),
              const SizedBox(height: 10),
              SignalStrengthText(
                quality: quality,
              ),
            ] else ...[
              const Text(
                'Sem conexão de rede',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoDetail extends StatelessWidget {
  final String label;
  final String value;

  const _InfoDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}
