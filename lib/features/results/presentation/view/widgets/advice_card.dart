import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:maxt_diagnostic/core/theme/brand_theme_colors.dart';
import 'package:maxt_diagnostic/domain/entities/advice_entity.dart';

class AdviceCard extends StatelessWidget {
  final AdviceEntity advice;

  const AdviceCard({super.key, required this.advice});

  @override
  Widget build(BuildContext context) {
    final brandColors =
        Theme.of(context).extension<BrandThemeColors>()!;
    final severityColors = _colorsForSeverity(brandColors, advice.severity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: severityColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _iconForSeverity(advice.severity),
            color: severityColors.icon,
            size: 24,
          ),
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
                    color: severityColors.title,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  advice.description,
                  style: TextStyle(
                    fontSize: 15,
                    color: severityColors.text,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  AdviceColors _colorsForSeverity(
    BrandThemeColors colors,
    AdviceSeverity severity,
  ) {
    switch (severity) {
      case AdviceSeverity.critical:
        return colors.adviceCritical;
      case AdviceSeverity.warning:
        return colors.adviceWarning;
      case AdviceSeverity.good:
        return colors.adviceGood;
      case AdviceSeverity.info:
        return colors.adviceInfo;
    }
  }

  IconData _iconForSeverity(AdviceSeverity severity) {
    switch (severity) {
      case AdviceSeverity.critical:
      case AdviceSeverity.warning:
        return LucideIcons.alertTriangle;
      case AdviceSeverity.good:
        return LucideIcons.checkCircle2;
      case AdviceSeverity.info:
        return LucideIcons.info;
    }
  }
}
