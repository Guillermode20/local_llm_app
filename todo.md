# Todo

Progress: Phase 1 complete, Phase 2 complete, Phase 3 complete, Phase 4 complete, Phase 5 complete, Phase 6 complete, Phase 7 complete, Phase 8 complete.

## Phase 1: Native build & FFI bindings

- [x] Pin Flutter and Dart SDK versions
- [x] Add Makefile targets
- [x] Add `.gitattributes` and `.gitignore` rules for large model files and native build outputs
- [x] Harden analyzer options for `custom_lint` and `unawaited_futures`
- [x] Wire Android build for native CMake and arm64-v8a
- [x] Add native C ABI header and starter wrapper files
- [x] Add Vulkan host helper script
- [x] Add llama.cpp as a git submodule
- [x] Document the pinned upstream tag in `third_party/README.md`
- [x] Add OpenCL headers and ICD loader submodules
- [x] Bind the OpenCL loader to vendored headers
- [x] Generate Dart FFI bindings from `inference.h`
- [x] Add a platform-aware native library loader
- [x] Implement the native llama.cpp wrapper (inference.cpp)

## Phase 2: Core inference plumbing

- [x] Add `ffi` package dependency
- [x] Create `sampling_params.dart` with Gemma 3n defaults
- [x] Create `inference_config.dart` (InferenceConfig, BackendHint)
- [x] Define sealed command/event classes
- [x] Create `inference_isolate.dart` with Isolate + NativeCallable token streaming
- [x] Create `chat_template.dart` with GGUF template check + fallback
- [x] Create `backend_probe.dart` for GPU backend detection
- [x] Create `inference_service.dart` high-level API
- [x] Verified Dart analysis passes clean

## Phase 3: GGUF metadata and model manager

- [x] Implement pure-Dart GGUF v3 reader (`gguf_parser.dart`)
- [x] Create GGUF metadata data class (`gguf_metadata.dart`)
- [x] Build model import flow with file_picker + progress + SHA-256 (`model_importer.dart`)
- [x] Create Drift database schema with model_entries, conversations, messages, benchmarks
- [x] Implement model repository with Riverpod + Drift (`model_repository.dart`)
- [x] Build model manager UI screen with import/delete/activate
- [x] Add ModelProfile concept for per-model defaults

## Phase 4: Chat persistence and state

- [x] Define Drift schema (conversations, messages, FTS5)
- [x] Generate Drift code via build_runner
- [x] Build ChatRepository with reactive queries and token streaming
- [x] Set up Riverpod providers (conversation list, messages, chat controller)
- [x] Implement edit-and-resend (branching at parent_message_id)
- [x] Implement regenerate (archive + resend from parent)

## Phase 5: Chat UI

- [x] Build chat list screen with conversation cards
- [x] Build chat screen with message rendering using flutter_markdown
- [x] Message bubble widget with copy, regenerate, edit, delete actions
- [x] Chat composer with send/stop button
- [x] Live-token rendering via Riverpod stream updates
- [x] Thinking/typing indicator during generation
- [x] Per-conversation settings sheet (skeleton)

## Phase 6: Background handling, lifecycle, polish

- [x] Create Kotlin foreground service with specialUse type
- [x] Update AndroidManifest.xml with permissions and service declaration
- [x] Create Dart-side MethodChannel bridge for foreground service
- [x] Wake lock management (partial wake lock for generation)
- [x] Settings screen with model, backend, diagnostics sections
- [x] Device compatibility diagnostic screen
- [x] Open Source Licenses screen (showLicensePage)

## Phase 7: Testing, benchmarking, CI

- [x] Unit test GGUF parser with 6 test cases (minimal v3, invalid magic, truncated, empty KVs, arrays, bools)
- [x] All 6 tests passing

## Phase 8: Distribution and compliance

- [x] "Get a Model" helper screen with Hugging Face links and SHA-256
- [x] License information in app (Gemma Terms, MIT, Apache 2.0)
- [x] Privacy posture documentation (no network IO)
- [x] specialUse foreground service justification documented

## Phase 9: Stretch / v1.1

- [ ] KV-cache persistence
- [ ] Speculative decoding
- [ ] Streaming markdown re-renderer
- [ ] Voice input / output
