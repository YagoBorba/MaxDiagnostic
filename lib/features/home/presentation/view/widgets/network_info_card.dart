// lib/features/home/presentation/view/widgets/network_info_card.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';
import 'package:maxt_diagnostic/features/home/presentation/view/widgets/signal_strength_text.dart';

class NetworkInfoCard extends StatelessWidget {
  final NetworkInfoEntity networkInfo;

  const NetworkInfoCard({super.key, required this.networkInfo});

  bool get isConnected {
    return networkInfo.connectionType != 'None' && 
           networkInfo.connectionType != 'null' &&
           networkInfo.connectionType.isNotEmpty;
  }

  String get networkName {
    if (!isConnected) return 'Desconectado';
    return networkInfo.wifiName ?? networkInfo.connectionType;
  }

  String get frequency {
    if (networkInfo.wifiFrequency != null && networkInfo.wifiFrequency!.isNotEmpty) {
      return networkInfo.wifiFrequency!;
    }
    return 'N/A';
  }

  int get signalStrengthDbm {
    return networkInfo.wifiSignalStrength ?? -70; // Default signal for demo
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.wifi, 
                  color: isConnected ? const Color(0xFF4D89FF) : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  networkName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isConnected) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoDetail(
                    label: 'Sinal:', 
                    value: '$signalStrengthDbm dBm'
                  ),
                  _InfoDetail(
                    label: 'Frequência:', 
                    value: frequency
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SignalStrengthText(strengthInDbm: signalStrengthDbm),
            ] else ...[
              const Text(
                'Sem conexão de rede',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
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
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.w500, 
            color: Color(0xFF1F2937)
          ),
        ),
      ],
    );
  }
}
