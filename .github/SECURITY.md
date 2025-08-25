# Security Policy

## Reporting a Vulnerability

We take security seriously and appreciate your efforts to responsibly disclose vulnerabilities.

- Please DO NOT open public GitHub issues for security vulnerabilities
- Instead, report security issues via one of the following private channels:
  - Email: [add-your-security-contact@email.com]
  - GitHub Security Advisory (if available)

Provide as much detail as possible, including:
- Affected versions and environment
- Steps to reproduce the vulnerability
- Potential impact
- Any known mitigations

We will acknowledge your report within 72 hours and provide an estimated timeline for fixes.

## Supported Versions

We generally support the latest stable release on `main` and the current development branch `develop`.

## Security Best Practices for Contributors

- Never commit secrets, credentials, or API keys
- Use environment variables or secure storage
- Validate and sanitize all external inputs
- Follow the project's coding standards and dependency policies
- Keep dependencies updated and avoid known vulnerable versions

## Dependency Management

- Run `flutter pub outdated` regularly
- Avoid introducing packages with known vulnerabilities
- Prefer well-maintained and popular packages

## Handling Sensitive Data

- Do not log sensitive information (tokens, passwords, etc.)
- Avoid storing sensitive data in plaintext
- Use platform-secure storage mechanisms when needed

## Disclosure Policy

- We follow responsible disclosure practices
- We may request a reasonable embargo period while fixes are developed and tested
- Credits will be given to reporters who follow this policy
