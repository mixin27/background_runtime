# Contributing to background_runtime

Thank you for considering contributing. This plugin aims to be production-grade — every contribution should uphold that standard.

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By participating, you agree to uphold its terms.

## How to Contribute

### Report Bugs

Open a [bug report](https://github.com/mixin27/background_runtime/issues/new?template=bug_report.md) with:

- A clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Platform and environment details

### Suggest Features

Open a [feature request](https://github.com/mixin27/background_runtime/issues/new?template=feature_request.md) describing the motivation, proposed API, and alternatives considered.

### Submit Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/my-change`)
3. Commit your changes following conventional commits
4. Push and open a PR against `main`

## Development Setup

### Prerequisites

- Flutter `>=3.22.0`
- Dart `^3.5.0`

### Setup

```bash
git clone https://github.com/mixin27/background_runtime.git
cd background_runtime
dart pub get
```

### Run Tests

```bash
# Platform interface
(cd background_runtime_platform_interface && flutter test)

# App-facing package
(cd background_runtime && flutter test)
```

### Run Analysis

```bash
dart analyze
```

## Pull Request Standards

Every PR must:

- Compile with zero errors
- Pass all tests
- Add tests for new functionality
- Produce zero analyzer warnings or lints
- Update CHANGELOG.md
- Not contain TODOs, placeholder logic, or dead code
- Not break the public API without deprecation

## Coding Guidelines

- Follow [Effective Dart](https://dart.dev/effective-dart)
- Follow SOLID principles and Clean Architecture
- Prefer immutable models with value equality
- Use typed exceptions, never generic `Exception`
- Avoid platform-specific concepts in Dart API
- Keep methods short and files focused
- Prefer descriptive names over brevity

See [AGENTS.md](AGENTS.md) for detailed engineering principles.

## Architecture

```
Dart API → Platform Interface → MethodChannel / EventChannel → Native Implementation
```

Native implementations follow a Service → Repository → Native Runtime → Platform Bridge pattern.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
