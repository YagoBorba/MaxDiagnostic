import 'package:flutter/material.dart';

enum SignalQuality { poor, normal, excellent }

class SignalStrengthText extends StatelessWidget {
  final int strengthInDbm;

  const SignalStrengthText({super.key, required this.strengthInDbm});

  SignalQuality _getSignalQuality(int dBm) {
    final absStrength = dBm.abs();
    if (absStrength <= 55) return SignalQuality.excellent;
    if (absStrength <= 70) return SignalQuality.normal;
    return SignalQuality.poor;
  }

  Color _getQualityColor(SignalQuality quality) {
    switch (quality) {
      case SignalQuality.excellent:
        return const Color(0xFF16A34A); // Green
      case SignalQuality.normal:
        return const Color(0xFFD97706); // Amber
      case SignalQuality.poor:
        return const Color(0xFFDC2626); // Red
    }
  }

  String _getQualityLabel(SignalQuality quality) {
    switch (quality) {
      case SignalQuality.excellent:
        return 'Excelente';
      case SignalQuality.normal:
        return 'Normal';
      case SignalQuality.poor:
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
