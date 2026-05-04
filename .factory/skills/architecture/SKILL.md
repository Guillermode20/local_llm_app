---
name: architecture
description: Overview of the Local LLM App architecture, module responsibilities, and data flow
---

# Architecture Overview

The Local LLM App is a Flutter desktop application that runs LLM inference locally via native FFI bindings.

## Module Map

```
┌─────────────────────────────────────────────────────┐
│                    UI Layer                          │
│  screens/ (ChatList, Chat, Settings, ModelManager)  │
│  widgets/ (MessageBubble, ChatComposer)              │
└──────────────┬──────────────────────────────────────┘
               │ Riverpod providers
┌──────────────▼──────────────────────────────────────┐
│                Service Layer                         │
│  chat/ (ChatRepository, ChatProviders)              │
│  models/ (ModelRepository, ModelImporter)            │
│  inference/ (InferenceService, InferenceIsolate)     │
└──────┬──────────────────────────────────────┬───────┘
       │ Drift/SQLite                         │ FFI
┌──────▼──────────┐             ┌─────────────▼──────┐
│   Data Layer    │             │  Native Layer       │
│  db/database    │             │  native/ (bindings) │
│  (Drift ORM)    │             │  llama.cpp (C++)    │
└─────────────────┘             └─────────────────────┘
```

## Data Flow

1. **Model Import**: User picks a `.gguf` file → `ModelImporter` copies to app storage → `ModelRepository` indexes it → metadata stored in Drift → SHA-256 hash computed
2. **Inference**: User sends a message → `ChatRepository` formats prompt → `InferenceService` sends command to `InferenceIsolate` → isolate calls native FFI bindings → llama.cpp processes tokens → tokens stream back via events
3. **Storage**: Conversations and messages persisted in SQLite via Drift ORM. FTS5 full-text search index on message content.
4. **UI State**: Riverpod providers manage reactive state. Chat list, active conversation, model selection all flow through providers.

## Key Dependencies

- **Riverpod**: State management
- **Drift + SQLite**: Local persistence with FTS5 search
- **FFI + llama.cpp**: Native LLM inference
- **custom_lint + riverpod_lint**: Static analysis
- **flutter_markdown**: Render LLM markdown output
