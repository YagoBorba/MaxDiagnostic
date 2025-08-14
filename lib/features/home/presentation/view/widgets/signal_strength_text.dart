import 'package:flutter/material.dart';

enum SignalQuality {
  bad,
  good,
  excellent,
}

class SignalStrengthText extends StatelessWidget {
  final int strengthInDbm;

  const SignalStrengthText({super.key, required this.strengthInDbm});

  SignalQuality _getSignalQuality(int dBm) {
    final absStrength = dBm.abs();
    if (absStrength <= 55) return SignalQuality.excellent;
    if (absStrength <= 75) return SignalQuality.good;
    return SignalQuality.bad;
  }

  Color _getQualityColor(SignalQuality quality) {
    switch (quality) {
      case SignalQuality.excellent:
        return const Color(0xFF16A34A); // Green
      case SignalQuality.good:
        return const Color(0xFFD97706); // Amber
      case SignalQuality.bad:
        return const Color(0xFFDC2626); // Red
    }
  }

  String _getQualityLabel(SignalQuality quality) {
    switch (quality) {
      case SignalQuality.excellent:
        return 'Excelente';
      case SignalQuality.good:
        return 'Bom';
      case SignalQuality.bad:
        return 'Ruim';
    }
  }

  @override
  Widget build(BuildContext context) {
    final quality = _getSignalQuality(strengthInDbm);
    return Text(
      _getQualityLabel(quality),
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _getQualityColor(quality),
      ),
    );
  }
}
