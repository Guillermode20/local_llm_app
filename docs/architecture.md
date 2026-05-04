# Architecture

```mermaid
graph TD
    subgraph UI["UI Layer (lib/src/ui/)"]
        screens["screens/ (ChatList, Chat, Settings, ModelManager)"]
        widgets["widgets/ (MessageBubble, ChatComposer)"]
    end

    subgraph Service["Service Layer (lib/src/)"]
        chat["chat/ (ChatRepository, ChatProviders)"]
        models["models/ (ModelRepository, ModelImporter, ModelProfile)"]
        inference["inference/ (InferenceService, InferenceIsolate)"]
        gguf["gguf/ (GGUFParser)"]
    end

    subgraph Data["Data Layer"]
        db["db/ (Drift ORM - SQLite)"]
        native["native/ (FFI Bindings)"]
    end

    subgraph External["External"]
        llama["llama.cpp (submodule)"]
        gguf_file["GGUF Model Files (.gguf)"]
    end

    screens --> chat
    screens --> models
    screens --> inference
    widgets --> screens
    chat --> db
    chat --> inference
    models --> gguf
    models --> db
    inference --> native
    native --> llama
    gguf --> gguf_file
    llama --> gguf_file
```

## Data Flow

1. **Model Import**: User picks a `.gguf` file from disk → `ModelImporter` copies it to app-private storage → `ModelRepository` indexes it → metadata parsed via `GGUFParser` → persisted in SQLite via Drift.
2. **Inference**: User sends a message → `ChatRepository` formats the prompt using `ChatTemplate` → `InferenceService` sends an `InferenceCommand` → `InferenceIsolate` processes it in a background isolate → native FFI bindings call into llama.cpp → tokens stream back as `InferenceEvent`s.
3. **Persistence**: Conversations and messages stored in SQLite via Drift ORM. Full-text search (FTS5) on message content for search.

## Key Design Decisions

- **Background Isolate**: All LLM inference runs in a separate Dart isolate to keep the UI responsive.
- **FFI**: Direct bindings to llama.cpp via `dart:ffi` for maximum inference performance.
- **Drift ORM**: Type-safe database access with migrations; schema defined in `database.dart`.
- **Riverpod**: Reactive state management; providers auto-dispose when no longer listened to.
