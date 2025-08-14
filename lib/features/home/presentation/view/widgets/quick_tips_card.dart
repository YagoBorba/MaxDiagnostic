import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class QuickTipsCard extends StatelessWidget {
  const QuickTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tips = [
      'Aproxime-se do roteador para melhorar o sinal.',
      'Evite obstáculos como paredes e espelhos.',
      'Reduza o número de dispositivos conectados à rede.',
    ];

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.lightbulb, color: Color(0xFFF59E0B)),
                SizedBox(width: 8),
                Text(
                  'Dicas Rápidas',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.w600, 
                    color: Color(0xFF374151)
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tips.map((tip) => _QuickTipItem(text: tip)),
          ],
        ),
      ),
    );
  }
}

class _QuickTipItem extends StatelessWidget {
  final String text;
  const _QuickTipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFFBBF24),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: Color(0xFF4B5563)),
            ),
          ),
        ],
      ),
    );
  }
}
