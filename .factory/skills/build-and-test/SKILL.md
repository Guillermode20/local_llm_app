---
name: build-and-test
description: Build, format, analyze, and test the Local LLM Flutter application
---

# Build and Test

This skill provides instructions for building, formatting, analyzing, and testing the Local LLM Flutter application.

## Commands

- `make fmt` — Format all Dart source files
- `make analyze` — Run static analysis
- `make test` — Run all tests
- `flutter pub get` — Install dependencies
- `dart run build_runner build --delete-conflicting-outputs` — Regenerate code-gen files

## Tests

Tests use `flutter_test`. Run individual test files with:
```
flutter test test/<path_to_test>
```

## Code Generation

After modifying Drift database schemas or Riverpod providers, regenerate:
```
dart run build_runner build --delete-conflicting-outputs
```
