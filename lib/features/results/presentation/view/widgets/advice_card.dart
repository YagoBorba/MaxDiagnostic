import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:maxt_diagnostic/domain/entities/advice_entity.dart';

class AdviceCard extends StatelessWidget {
  final AdviceEntity advice;
  const AdviceCard({super.key, required this.advice});

  @override
  Widget build(BuildContext context) {
    final theme = _getTheme(advice.severity);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(theme.iconData, color: theme.iconColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advice.title,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: theme.titleColor),
                ),
                const SizedBox(height: 4),
                Text(
                  advice.description,
                  style: TextStyle(
                      fontSize: 15, color: theme.textColor, height: 1.4),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  _AdviceTheme _getTheme(AdviceSeverity severity) {
    switch (severity) {
      case AdviceSeverity.critical:
        return _AdviceTheme(
            backgroundColor: const Color(0xFFFEF2F2),
            iconColor: const Color(0xFFEF4444),
            titleColor: const Color(0xFFB91C1C),
            textColor: const Color(0xFF991B1B),
            iconData: LucideIcons.alertTriangle);
      case AdviceSeverity.warning:
        return _AdviceTheme(
            backgroundColor: const Color(0xFFFFFBEB),
            iconColor: const Color(0xFFF59E0B),
            titleColor: const Color(0xFFB45309),
            textColor: const Color(0xFF92400E),
            iconData: LucideIcons.alertTriangle);
      case AdviceSeverity.good:
        return _AdviceTheme(
            backgroundColor: const Color(0xFFF0FDF4),
            iconColor: const Color(0xFF22C55E),
            titleColor: const Color(0xFF15803D),
            textColor: const Color(0xFF166534),
            iconData: LucideIcons.checkCircle2);
      case AdviceSeverity.info:
        return _AdviceTheme(
            backgroundColor: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF3B82F6),
            titleColor: const Color(0xFF1E40AF),
            textColor: const Color(0xFF1D4ED8),
            iconData: LucideIcons.info);
    }
  }
}

class _AdviceTheme {
  final Color backgroundColor;
  final Color iconColor;
  final Color titleColor;
  final Color textColor;
  final IconData iconData;

  _AdviceTheme({
    required this.backgroundColor,
    required this.iconColor,
    required this.titleColor,
    required this.textColor,
    required this.iconData,
  });
}
