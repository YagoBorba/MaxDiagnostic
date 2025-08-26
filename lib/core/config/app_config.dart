class AppConfig {
  final int signalExcellentThresholdDbm;
  final Duration homeRefreshInterval;

  AppConfig({
    this.signalExcellentThresholdDbm = -45,
    this.homeRefreshInterval = const Duration(seconds: 4),
  });

  bool isSignalExcellent(int? dbm) {
    if (dbm == null) return false;
    return dbm >= signalExcellentThresholdDbm;
  }
}
