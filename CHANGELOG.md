# Changelog

## [1.0.0] - 2026-11-25

First release.

- Guided network diagnostic: Wi-Fi details (SSID, BSSID, signal, band, channel, standard and, on Android, link speed), public IP and provider, and device information.
- Speed test (download, upload, ping and jitter) against a self-hosted LibreSpeed server, with live progress, a global timeout and progress watchdogs.
- Server load control: the app reserves a slot before each test and waits in a queue with the estimated time when the server is busy. The server limits concurrent tests with `MAX_CONCURRENT_TESTS`, and reservations are made under a lock so concurrent requests never exceed it.
- Recommendations for Wi-Fi bottlenecks, latency, jitter and streaming quality.
- PDF report with the speed test, connection, Wi-Fi before and after the test and device data, shared through the native share sheet.
- Demo mode (`--dart-define=DEMO_MODE=true`) that runs without a server and labels the results as simulated. The APK attached to this release is built in demo mode.
- Docker setup for the LibreSpeed server, with a smoke test of the endpoints and the capacity flow.
- Architecture and self-hosting guides.
- CI: formatting, analysis, unit tests, release APK build and the server smoke test on every pull request.
