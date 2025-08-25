# Conventional Commits Reference

## Format

```
<emoji> <type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Common Types with Emojis

| Emoji | Code                    | Type       | Description                       |
| ----- | ----------------------- | ---------- | --------------------------------- |
| ✨    | `:sparkles:`            | `feat`     | Introduce new features            |
| 🐛    | `:bug:`                 | `fix`      | Fix a bug                         |
| 📝    | `:memo:`                | `docs`     | Add or update documentation       |
| 🎨    | `:art:`                 | `style`    | Improve structure/format of code  |
| ♻️    | `:recycle:`             | `refactor` | Refactor code                     |
| ⚡️   | `:zap:`                 | `perf`     | Improve performance               |
| ✅    | `:white_check_mark:`    | `test`     | Add, update, or pass tests        |
| 🔧    | `:wrench:`              | `chore`    | Add or update configuration files |
| 🚀    | `:rocket:`              | `build`    | Deploy stuff                      |
| 👷    | `:construction_worker:` | `ci`       | Add or update CI build system     |
| 💥    | `:boom:`                | `break`    | Introduce breaking changes        |
| 🔒    | `:lock:`                | `security` | Fix security issues               |
| 🌐    | `:globe_with_meridians:`| `i18n`     | Internationalization and locale   |

## Project-Specific Scopes

Para MaxDiagnostic, use estes escopos específicos:

### Feature Scopes
- `speed-test`: Funcionalidades de teste de velocidade
- `wifi-analyzer`: Análise de redes WiFi
- `network-info`: Informações de rede
- `home`: Tela inicial e navegação
- `settings`: Configurações do app

### Technical Scopes  
- `core`: Infraestrutura e dependency injection
- `domain`: Entidades e casos de uso
- `data`: Implementações de repositórios
- `ui`: Componentes de interface
- `l10n`: Localização e traduções
- `cubit`: Gerenciamento de estado BLoC
- `routing`: Navegação e rotas

### Platform Scopes
- `android`: Específico para Android
- `ios`: Específico para iOS
- `web`: Específico para Web
- `windows`: Específico para Windows

## Examples

### Features
```bash
# New feature
✨ feat(speed-test): implement download speed measurement algorithm

# Feature enhancement  
✨ feat(wifi-analyzer): add network signal strength visualization

# UI improvement
✨ feat(ui): create responsive network info cards
```

### Bug Fixes
```bash
# Critical bug
🐛 fix(network-info): resolve null pointer exception on network detection

# UI bug
🐛 fix(home): correct alignment issues on small screens

# Performance issue
🐛 fix(speed-test): prevent memory leak during long tests
```

### Documentation
```bash
# API documentation
📝 docs(domain): add comprehensive comments to speed test entities

# README updates
📝 docs: update installation instructions for Flutter 3.19

# Architecture documentation
📝 docs(core): document dependency injection patterns
```

### Refactoring
```bash
# Code organization
♻️ refactor(home): extract network status logic to separate cubit

# Architecture improvement
♻️ refactor(data): implement repository pattern for network services

# Code cleanup
♻️ refactor(ui): consolidate theme constants in single file
```

### Testing
```bash
# Unit tests
✅ test(speed-test): add comprehensive coverage for speed calculations

# Widget tests
✅ test(home): verify network info card displays correct data

# Integration tests
✅ test(e2e): add end-to-end speed test workflow
```

### Configuration
```bash
# Development setup
🔧 chore: update Flutter version to 3.19.6

# Dependencies
🔧 chore(deps): upgrade flutter_bloc to v8.1.3

# Build configuration
🔧 chore(android): update targetSdk to API 34
```

### Localization
```bash
# New translations
🌐 i18n: add Portuguese translations for speed test results

# Translation updates
🌐 i18n(home): update network status messages

# Locale support
🌐 i18n: implement Brazilian Portuguese number formatting
```

## Breaking Changes

Add `!` after the type for breaking changes:

```bash
💥 feat(core)!: migrate to new dependency injection pattern

💥 refactor(domain)!: change speed test result data structure
```

## Body and Footer Guidelines

### Body
- Use imperative mood ("add" not "added")
- Explain the **what** and **why**, not the how
- Keep lines under 72 characters
- Separate paragraphs with blank lines

### Footer
- Reference issues: `Closes #123`, `Fixes #456`, `Relates to #789`
- Breaking changes: `BREAKING CHANGE: description`
- Co-authors: `Co-authored-by: Name <email@example.com>`

## Complete Examples

### Simple Feature
```bash
✨ feat(speed-test): add real-time progress indicator

Implement a circular progress indicator that updates in real-time
during speed tests, showing both percentage and current speed.

Closes #45
```

### Bug Fix with Context
```bash
🐛 fix(wifi-analyzer): resolve crash on networks without SSID

The app was crashing when scanning networks that don't broadcast
their SSID. Added null safety checks and proper error handling.

The fix ensures:
- Hidden networks are displayed as "Unknown Network"
- No crashes occur during network scanning
- Error states are properly communicated to users

Fixes #67
Relates to #23
```

### Breaking Change
```bash
💥 refactor(core)!: migrate to new GetIt service locator pattern

BREAKING CHANGE: All dependency injection calls now require async
initialization. Update your main.dart to call `await setupDI()`
before `runApp()`.

Migration guide:
- Replace `di.sl<Service>()` with `di.get<Service>()`
- Add async/await to dependency resolution
- Update tests to call `await setupTestDI()`

Closes #89
```

## Validation Checklist

Before committing, ensure:
- [ ] Emoji matches the type of change
- [ ] Type accurately describes the change
- [ ] Scope is relevant to MaxDiagnostic
- [ ] Description is clear and concise
- [ ] Body explains context when needed
- [ ] Issues are properly referenced
- [ ] Breaking changes are clearly marked

## Tools Integration

### Git Hooks
Consider setting up commit-msg hooks to validate format:

```bash
# .git/hooks/commit-msg
#!/bin/sh
commit_regex='^[🎨🐛📝♻️⚡️✅🔧🚀👷💥🔒🌐✨][[:space:]]+(feat|fix|docs|style|refactor|perf|test|chore|build|ci|break|security|i18n)(\(.+\))?!?:[[:space:]].+'

if ! grep -qE "$commit_regex" "$1"; then
    echo "Invalid commit message format!"
    echo "Use: <emoji> <type>[scope]: <description>"
    exit 1
fi
```

### VS Code Integration
Add to your VS Code settings:

```json
{
  "gitmoji.additionalEmojis": [
    {
      "emoji": "💥",
      "code": ":boom:",
      "description": "Introduce breaking changes"
    }
  ]
}
```
