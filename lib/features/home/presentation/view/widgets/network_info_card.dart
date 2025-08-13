// lib/features/home/presentation/view/widgets/network_info_card.dart
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:maxt_diagnostic/data/models/network_info_model.dart'; // Changed import
import 'package:maxt_diagnostic/features/home/presentation/view/widgets/signal_strength_text.dart';

class NetworkInfoCard extends StatelessWidget {
  final NetworkInfoModel networkInfo; // Changed to use the Model

  const NetworkInfoCard({super.key, required this.networkInfo});

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
                  color: networkInfo.isConnected
                      ? const Color(0xFF4D89FF)
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  networkInfo.networkName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E29B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (networkInfo.isConnected) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoDetail(
                    label: 'Sinal:',
                    value: '${networkInfo.signalStrengthDbm} dBm',
                  ),
                  _InfoDetail(
                    label: 'Frequência:',
                    value: networkInfo.frequency,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SignalStrengthText(
                strengthInDbm: networkInfo.signalStrengthDbm,
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
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}