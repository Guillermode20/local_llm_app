# Local LLM App

A Flutter desktop application for running large language models locally on your machine via FFI bindings to llama.cpp.

## Quick Start

```bash
# 1. Install dependencies
flutter pub get

# 2. Regenerate code-gen (Drift, Riverpod)
dart run build_runner build --delete-conflicting-outputs

# 3. Verify setup
make analyze
make test

# 4. Run the app
flutter run
```

## Prerequisites

- Flutter SDK >= 3.24.0
- Dart SDK >= 3.5.0
- A GGUF model file (e.g., Gemma 3, Llama 3) for inference

## Project Structure

See [AGENTS.md](AGENTS.md) for a detailed breakdown of the module layout, coding conventions, and testing guidelines.

## Documentation

- [Architecture Overview](docs/architecture.md) — Module structure and data flow
- [AGENTS.md](AGENTS.md) — Contributor guidelines, commands, and conventions
