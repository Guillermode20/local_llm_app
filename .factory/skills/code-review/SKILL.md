---
name: code-review
description: Code review checklist and guidelines for the Local LLM App
---

# Code Review

## Review Checklist

1. **Functionality**: Does the change work as described?
2. **Type Safety**: Does `make analyze` pass without errors?
3. **Tests**: Are there tests for new/changed logic? Do all tests pass?
4. **Formatting**: Run `make fmt` — no formatting drift.
5. **Naming**: Follow lowerCamelCase (variables), UpperCamelCase (classes), lowercase_with_underscores (files).
6. **Riverpod**: Use `@riverpod` annotation for new providers. Avoid manual Provider declarations.
7. **Drift**: After modifying table definitions, regenerate with `dart run build_runner build`.
8. **Error Handling**: FFI calls should be wrapped in try-catch. User-facing errors should surface in the UI.
9. **Performance**: Avoid duplicate provider reads. Cache expensive FFI computations in isolates.

## File Conventions

- `*_providers.dart` — Riverpod provider definitions
- `*_repository.dart` — Data access and business logic
- `*_test.dart` — Corresponding test file in `test/`
- `*.g.dart` — Auto-generated (Drift, JSON, Riverpod); checked in
