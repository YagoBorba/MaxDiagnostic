enum SignalQuality { excellent, normal, poor }

class AppConfig {
  final int signalExcellentThresholdDbm; // >= this => excellent
  final int signalNormalThresholdDbm; // >= this => normal

  final Duration homeRefreshInterval;

  final List<String> quickTips;
  final String disabledStartMessage;
  final String speedTestUrl;

  AppConfig({
  this.signalExcellentThresholdDbm = -60,
    this.signalNormalThresholdDbm = -70,
    this.homeRefreshInterval = const Duration(seconds: 4),
    this.quickTips = const [
      'Aproxime-se do roteador para melhorar o sinal.',
      'Evite obstáculos como paredes e espelhos.',
      'Reduza o número de dispositivos conectados à rede.',
    ],
    this.disabledStartMessage = 'Aproxime-se do roteador para iniciar o teste.',
    this.speedTestUrl = 'about:blank',
  });

  bool isSignalExcellent(int? dbm) {
    if (dbm == null) return false;
  return dbm > signalExcellentThresholdDbm;
  }

  SignalQuality getSignalQuality(int? dbm) {
    if (dbm == null) return SignalQuality.poor;
  if (dbm > signalExcellentThresholdDbm) return SignalQuality.excellent;
    if (dbm >= signalNormalThresholdDbm) return SignalQuality.normal;
    return SignalQuality.poor;
  }

  String qualityLabel(SignalQuality q) {
    switch (q) {
      case SignalQuality.excellent:
        return 'Excelente';
      case SignalQuality.normal:
        return 'Normal';
      case SignalQuality.poor:
        return 'Ruim';
    }
  }
}
