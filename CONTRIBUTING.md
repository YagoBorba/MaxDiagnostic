# Contributing to MaxDiagnostic

## 🎯 Overview

MaxDiagnostic is a Flutter network diagnostic application using Clean Architecture with BLoC pattern. We appreciate your contribution to make this tool even better!

## 🌿 Git Workflow (GitFlow)

This project uses **GitFlow** as the branching model. Understand the structure:

### Main Branches

- **`main`**: Production code, always stable
- **`develop`**: Development branch, feature integration

### Supporting Branches

- **`feature/*`**: New features (branches from `develop`)
- **`release/*`**: Release preparation (branches from `develop`)
- **`hotfix/*`**: Urgent production fixes (branches from `main`)

### Workflow

1. **For new features:**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/my-new-feature
   # ... develop feature ...
   git push origin feature/my-new-feature
   # Open Pull Request to develop
   ```

2. **For hotfixes:**
   ```bash
   git checkout main
   git pull origin main
   git checkout -b hotfix/critical-fix
   # ... implement fix ...
   git push origin hotfix/critical-fix
   # Open Pull Request to main AND develop
   ```

## 💻 Development Environment Setup

### Prerequisites

- Flutter 3.19.6+ (Dart 3.3.0+)
- Git configured
- Code editor (VS Code recommended)

### Initial Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/YagoBorba/MaxDiagnostic.git
   cd MaxDiagnostic
   ```

2. **Setup Flutter:**
   ```bash
   flutter doctor
   flutter pub get
   ```

3. **Generate localization files:**
   ```bash
   flutter gen-l10n
   ```

4. **Run tests:**
   ```bash
   flutter test
   ```

5. **Check code analysis:**
   ```bash
   flutter analyze
   ```

## 🏗️ Project Architecture

### Clean Architecture with BLoC

```
lib/
├── core/di/              # Dependency Injection (GetIt)
├── domain/              # Entities and use cases
├── data/                # Repository implementations
├── features/            # Feature-based organization
└── l10n/                # Localization files
```

### Mandatory Patterns

- **State Management**: BLoC/Cubit with `flutter_bloc`
- **Dependency Injection**: GetIt service locator
- **Error Handling**: Either<Failure, Success> with Dartz
- **Localization**: ARB files with Portuguese as default

## 📝 Commit Convention

We follow [Conventional Commits](./.github/COMMIT_CONVENTION.md) with emojis:

```bash
<emoji> <type>[optional scope]: <description>

[optional body]
[optional footer(s)]
```

**Examples:**
```bash
✨ feat(speed-test): implement download speed measurement
🐛 fix(wifi): resolve network adapter detection issue
📝 docs: update README with new installation steps
♻️ refactor(home): extract network info logic to separate cubit
```

## 🔄 Pull Request Process

### Before Submitting

- [ ] Code follows project standards
- [ ] Unit tests created/updated
- [ ] `flutter analyze` passes without warnings
- [ ] `flutter test` all tests passing
- [ ] Documentation updated if necessary
- [ ] Commits follow established convention

### Creating the PR

1. **Use the template**: Template will load automatically
2. **Descriptive title**: Follow commit convention
3. **Complete description**: Explain what, why, and how
4. **Link issues**: Use `Closes #123` or `Fixes #456`
5. **Mark reviewers**: At least one maintainer

### Review Process

- PRs require approval from at least 1 maintainer
- CI/CD must pass (analysis + tests)
- Feedback will be given constructively
- Changes may be requested

## 🧪 Testing

### Test Structure

```bash
test/
├── unit/                # Unit tests
├── widget/              # Widget tests
└── integration/         # Integration tests
```

### Running Tests

```bash
# All tests
flutter test

# Specific tests
flutter test test/unit/features/speed_test/

# With coverage
flutter test --coverage
```

### Test Requirements

- **New features**: Minimum 80% coverage
- **Bug fixes**: Test that reproduces the bug
- **Widgets**: Interaction and state tests
- **Cubits**: Tests for all possible states

## 🎨 Code Standards

### Dart/Flutter

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter_lints` configuration
- Maximum 80 characters per line
- Document public APIs

### Import Organization

```dart
// Dart imports
import 'dart:async';

// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:flutter_bloc/flutter_bloc.dart';

// Relative imports
import '../widgets/custom_widget.dart';
```

### Naming Conventions

- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables/Functions**: `camelCase`
- **Constants**: `SCREAMING_SNAKE_CASE`

## 🌐 Localization

### Adding New Strings

1. **Edit `lib/l10n/app_pt.arb`:**
   ```json
   {
     "my_new_string": "My text in Portuguese",
     "@my_new_string": {
       "description": "Description of usage context"
     }
   }
   ```

2. **Generate files:**
   ```bash
   flutter pub get
   ```

3. **Use in code:**
   ```dart
   AppLocalizations.of(context)!.my_new_string
   ```

## 🐛 Reporting Issues

Use our templates:
- 🐛 [Bug Report](./.github/ISSUE_TEMPLATE/bug_report.yml)
- ✨ [Feature Request](./.github/ISSUE_TEMPLATE/feature_request.yml)
- ❓ [Question](./.github/ISSUE_TEMPLATE/question.yml)

## 📞 Communication

- **Issues**: For bugs, features, and technical discussions
- **Pull Requests**: For code review
- **Discussions**: For ideas and general questions

## 🏆 Recognition

Contributors are automatically listed in the README. We appreciate every contribution, no matter the size!

---

**Useful Links:**
- [Conventional Commits](./.github/COMMIT_CONVENTION.md)
- [Code of Conduct](./CODE_OF_CONDUCT.md)
- [Security Policy](./.github/SECURITY.md)
- [Issue Templates](./.github/ISSUE_TEMPLATE/)
