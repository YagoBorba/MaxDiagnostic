# GitHub Copilot Instructions for MaxDiagnostic

## Project Overview
MaxDiagnostic is a Flutter network diagnostic application using Clean Architecture with BLoC pattern. The app performs network speed tests and WiFi analysis, targeting Portuguese-speaking users.

## Architecture Pattern: Clean Architecture
```
lib/
├── core/di/              # Dependency injection (GetIt)
├── domain/              # Business logic layer
│   ├── entities/        # Core business objects
│   ├── repositories/    # Abstract interfaces
│   └── usecases/        # Business use cases
├── data/                # External interfaces (not yet implemented)
├── features/            # Feature-based UI organization
└── l10n/                # Localization files
```

## Key Dependencies & Patterns

### State Management: BLoC/Cubit Pattern
- Use `flutter_bloc` with `Cubit` for state management
- States extend `Equatable` for value equality
- Example structure: `SpeedTestCubit` with `SpeedTestState` hierarchy
- Register Cubits in `core/di/injection_container.dart` using GetIt

### Dependency Injection: GetIt Service Locator
```dart
// Register in core/di/injection_container.dart
sl.registerFactory(() => YourCubit());

// Use in widgets via BlocProvider
BlocProvider(create: (context) => di.sl<YourCubit>())
```

### Functional Programming: Dartz Either
- Use `Either<Failure, Success>` for error handling
- Repository methods return `Future<Either<Failure, Result>>`
- Failures are defined in `core/error/failures.dart`

### Localization Setup
- ARB files in `lib/l10n/` (template: `app_pt.arb`)
- Configuration in `l10n.yaml` with Portuguese as default
- Generated files: `.dart_tool/flutter_gen/gen_l10n/`
- Access via `AppLocalizations.of(context)!.key_name`

## Critical Developer Workflows

### Essential Commands
```bash
# Clean and reinstall dependencies (fixes most issues)
flutter clean && flutter pub get

# Generate localization files (after ARB changes)
flutter gen-l10n

# Run analysis (must pass in CI)
flutter analyze

# Run tests (requires DI initialization)
flutter test
```

### Dependency Management Issues
- **Common Issue**: "Package not found" errors despite pubspec.yaml listing
- **Solution**: Run `flutter clean && flutter pub get` to regenerate `.dart_tool/`
- **Testing**: Always call `await di.init()` before widget tests

### Localization Workflow
1. Add keys to `lib/l10n/app_pt.arb`
2. Run `flutter pub get` (auto-generates files)
3. Use `AppLocalizations.of(context)!.your_key` in widgets
4. Files generate to `.dart_tool/flutter_gen/gen_l10n/`

## Project-Specific Conventions

### File Organization
- Features grouped by domain: `features/speed_test/`
- Each feature has: `cubit/`, `screens/`, `widgets/` subdirectories
- Domain layer separate from features: `domain/entities/`, `domain/repositories/`
- Core utilities in `core/di/` (dependency injection and errors)

### Import Patterns
```dart
// Feature imports use full package paths
import 'package:maxt_diagnostic/features/speed_test/cubit/speed_test_cubit.dart';

// Core DI imports use relative paths with alias
import 'core/di/injection_container.dart' as di;

// Generated localizations
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

### State Management Pattern
```dart
// Cubit structure with typed states
class FeatureCubit extends Cubit<FeatureState> {
  FeatureCubit() : super(FeatureInitial());
  
  void performAction() {
    emit(FeatureLoading());
    // Business logic
    emit(FeatureSuccess(result));
  }
}
```

### Error Handling Pattern
```dart
// Repository pattern with Either
Future<Either<Failure, Result>> methodName() async {
  try {
    final result = await externalService.call();
    return Right(result);
  } catch (e) {
    return Left(ServerFailure());
  }
}
```

## Development Environment
- **Container**: Dev container with Flutter 3.19.6 pre-installed
- **Target SDK**: Dart 3.3.0+
- **Platform**: Multi-platform (Android, iOS, Web, Windows)
- **CI/CD**: GitHub Actions on develop branch
- **Primary Language**: Portuguese (Brazil)

## Common Gotchas
1. **GetIt Registration**: New Cubits must be registered in `injection_container.dart`
2. **Localization**: Changes require `flutter pub get`, not just `flutter gen-l10n`
3. **Testing**: Widget tests fail without `await di.init()` call
4. **Clean Architecture**: Domain layer should not import Flutter or external packages (except Equatable/Dartz)
5. **File Paths**: Use absolute package imports, avoid relative paths in cross-layer imports
