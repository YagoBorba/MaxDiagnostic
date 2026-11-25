/// Demo mode, enabled at build time with `--dart-define=DEMO_MODE=true`.
///
/// The diagnostic is simulated and no speed test server is needed, so the
/// published APK can be explored without self-hosting LibreSpeed. Screens and
/// reports say that the results are simulated.
const bool kDemoMode = bool.fromEnvironment('DEMO_MODE');
