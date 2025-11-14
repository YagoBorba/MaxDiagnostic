import 'package:flutter/material.dart';
import 'package:maxt_diagnostic/core/config/app_config.dart';
import 'package:maxt_diagnostic/core/di/injection_container.dart' as di;
import 'package:maxt_diagnostic/core/theme/brand_theme_colors.dart';

class SignalStrengthText extends StatelessWidget {
  final SignalQuality quality;

  const SignalStrengthText({super.key, required this.quality});

  Color _getQualityColor(BuildContext context) {
    final brandColors =
        Theme.of(context).extension<BrandThemeColors>()!;
    switch (quality) {
      case SignalQuality.excellent:
        return brandColors.signalExcellent;
      case SignalQuality.normal:
        return brandColors.signalNormal;
      case SignalQuality.poor:
        return brandColors.signalPoor;
    }
  }

  String _getQualityLabel() {
    return di.sl<AppConfig>().qualityLabel(quality);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _getQualityLabel(),
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _getQualityColor(context),
      ),
    );
  }
}
