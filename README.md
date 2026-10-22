<a name="readme-top"></a>

<div align="center">

<h1 align="center">MaxDiagnostic</h1>

<br>

# Welcome to the MaxDiagnostic repository

---

<div align="center">

[![CI Status][ci-shield]][ci-link]
[![Project Type][type-shield]][type-link]
[![Flutter][flutter-shield]][flutter-link]
[![Dart][dart-shield]][dart-link]

</div>

[ci-shield]: https://github.com/YagoBorba/MaxDiagnostic/actions/workflows/main.yml/badge.svg?branch=develop
[ci-link]: https://github.com/YagoBorba/MaxDiagnostic/actions/workflows/main.yml
[type-shield]: https://img.shields.io/badge/Project-Cross--platform%20App-0A66C2?style=flat-square&labelColor=black
[type-link]: https://github.com/YagoBorba/MaxDiagnostic
[flutter-shield]: https://img.shields.io/badge/Flutter-3.35-02569B?style=flat-square&logo=flutter&labelColor=black
[flutter-link]: https://flutter.dev/
[dart-shield]: https://img.shields.io/badge/Dart-3.7%2B-0175C2?style=flat-square&logo=dart&labelColor=black
[dart-link]: https://dart.dev/

</br>

</div>

## ❤️ About the Project

> [!IMPORTANT]
> MaxDiagnostic is a cross-platform network diagnostic app built with Flutter. It guides the user through a complete check of the Wi-Fi and internet connection and generates a shareable PDF report.

The project was created to support the technical team of an internet service provider. Before opening a support ticket, the user runs a guided diagnostic that collects Wi-Fi, connection, device and speed test data in a single flow. The app then suggests what may be causing the problem and produces a report that can be sent to support, making it easier to tell real network failures apart from local issues such as weak Wi-Fi signal.

## ✨ What Can MaxDiagnostic Do?

- 📶 **Wi-Fi Analysis:**
    Reads SSID, BSSID, internal IP, signal strength (RSSI), frequency band (2.4/5 GHz), channel, Wi-Fi standard (802.11a/b/g/n/ac/ax) and, on Android, the Wi-Fi link speed.

- 🌍 **Connection Details:**
    Identifies the public IP address and the internet provider (ISP).

- 🚀 **Speed Test:**
    Measures download, upload, ping and jitter against a LibreSpeed server, with live progress for each stage of the test.

- 📉 **Before/After Signal Comparison:**
    Captures a Wi-Fi snapshot before and after the speed test to show signal changes during the measurement.

- 💡 **Smart Recommendations:**
    Detects Wi-Fi bottlenecks (download below 50% of the link speed), flags high latency and jitter, and classifies the connection quality for streaming.

- 📄 **PDF Report & Sharing:**
    Generates a report with speed test, connection, Wi-Fi and device data and shares it through the native share sheet.

- 🛡️ **Resilient Test Flow:**
    Uses a global timeout, progress watchdogs and safe abort handling so the diagnostic never hangs.

- 🇧🇷 **Localization:**
    Interface in Brazilian Portuguese, generated with Flutter `gen-l10n`.

## 🛠️ Under the Hood (Main Technologies)

- **[Flutter](https://flutter.dev/) & [Dart](https://dart.dev/):** Cross-platform UI for Android, iOS, Web, Windows, macOS and Linux.
- **[flutter_bloc](https://pub.dev/packages/flutter_bloc):** State management with Cubits.
- **[get_it](https://pub.dev/packages/get_it):** Dependency injection.
- **[dartz](https://pub.dev/packages/dartz):** Functional error handling with `Either` and `Failure`.
- **[go_router](https://pub.dev/packages/go_router):** Declarative navigation.
- **[flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview):** Headless WebView that runs the LibreSpeed test and streams results to Flutter.
- **[connectivity_plus](https://pub.dev/packages/connectivity_plus), [network_info_plus](https://pub.dev/packages/network_info_plus), [wifi_scan](https://pub.dev/packages/wifi_scan), [device_info_plus](https://pub.dev/packages/device_info_plus):** Network, Wi-Fi and device information.
- **[flutter_html_to_pdf](https://pub.dev/packages/flutter_html_to_pdf) & [share_plus](https://pub.dev/packages/share_plus):** PDF report generation and sharing.
- **[LibreSpeed](https://github.com/librespeed/speedtest) + [Docker](https://www.docker.com/):** Self-hosted speed test server for local development.
- **[GitHub Actions](https://github.com/features/actions):** Continuous integration (format, analyze and test).

## 🏗️ Architecture

The app follows **Clean Architecture**, keeping business rules independent from Flutter and external packages:

- **`core`:** configuration, dependency injection, errors, network info, theme and base use case.
- **`domain`:** entities, repository contracts, use cases (`GetInitialNetworkInfo`, `CheckServerReachability`, `RunDiagnosticTest`) and the advice service.
- **`data`:** datasources (device info, network info, speed test), models and the repository implementation.
- **`features`:** presentation layer for `home`, `diagnostic` and `results`, with Cubits, screens and widgets.

## 🚀 Getting Started

### Prerequisites

- **[Flutter SDK](https://docs.flutter.dev/get-started/install)** (stable channel; CI uses 3.35.2)
- **[Docker](https://www.docker.com/)** (to run the local speed test server)
- Android Studio or Xcode to run on mobile devices

### 1. Clone the repository

```bash
git clone https://github.com/YagoBorba/MaxDiagnostic.git
cd MaxDiagnostic
```

### 2. Start the LibreSpeed server

```bash
cd docker/librespeed
docker compose up -d
cd ../..
```

The server runs at **http://localhost:7000**.

### 3. Configure the environment

Create a `.env` file at the project root (it is loaded as an asset in `pubspec.yaml`) based on `.env.example`:

```env
SPEED_TEST_URL=http://localhost:7000/librespeed_runner.html
```

> [!TIP]
> On a physical device, replace `localhost` with the local IP address of the machine running Docker.

### 4. Install dependencies and generate translations

```bash
flutter pub get
flutter gen-l10n
```

### 5. Run the app

```bash
flutter run
```

## 📱 Platform Notes

- **Android/iOS:** location permission is required to read Wi-Fi details (SSID, BSSID and scan results).
- **Android:** Wi-Fi link speed is read through a platform channel.
- **Web:** network and speed test data are simulated, since browsers cannot access this information.

## 🧪 Quality & Tests

The CI pipeline runs on every push and pull request to `main` and `develop`:

```bash
dart format .
flutter analyze
flutter test --coverage
```

Unit tests use **bloc_test** and **mocktail** and cover the speed test datasource, the diagnostic repository, the `RunDiagnosticTest` use case and the `Home` and `Diagnostic` Cubits.

## 🧩 Project Structure

```text
lib/
    app/
        navigation/
    core/
        config/
        di/
        error/
        network/
        services/
        theme/
        usecases/
    data/
        datasources/
        models/
        repositories/
    domain/
        entities/
        repositories/
        services/
        usecases/
    features/
        diagnostic/
        home/
        results/
    l10n/
    services/
    main.dart

docker/
    librespeed/

test/
```

## 🤝 Contributing

Contributions are welcome. Please read the [Contributing Guide](CONTRIBUTING.md), the [Commit Convention](.github/COMMIT_CONVENTION.md) and the [Code of Conduct](CODE_OF_CONDUCT.md).

1. Fork the repository.
2. Create your feature branch from `develop`.
3. Commit your changes following the commit convention.
4. Push your branch.
5. Open a Pull Request.

## 📝 License

No `LICENSE` file is currently present in this repository. If you want, you can add one (for example, MIT) to define usage terms explicitly.

## 📬 Contact

- Email: yagoaborba@hotmail.com
- LinkedIn: https://www.linkedin.com/in/yagoborba/

---

<div align="right">
        <a href="#readme-top">Back to Top</a>
</div>
