# Local LLM Chat App for Android with Flutter, llama.cpp, and Gemma 3n E2B

## Part 1 — Architectural Plan & Decisions

This section sets the stack and the trade-offs. The defaults below are not negotiable for a "fuller" app of this scope; deviations are flagged.

### 1.1 Inference backend: build llama.cpp yourself, do not rely on `fllama` / `llama_cpp_dart` for production

The available Flutter packages are **not** suitable as the primary integration for a fuller app:

- **`fllama` (Telosnex)** is the most polished but bundles its own static llama.cpp build, doesn't expose a way to enable Vulkan/OpenCL on Android (its Android build is CPU-only by default), and its JS-style `OpenAiRequest` API is not a thin enough seam for things like KV-cache reuse, streaming cancellation mid-prompt-processing, GPU-layer tuning, GGUF metadata inspection, or per-conversation context management. Great prototype path; not a great foundation.
- **`llama_cpp_dart` (netdur)** ships ffigen-generated low-level bindings plus a `LlamaParent` managed-isolate wrapper. The bindings are useful, but the package leaves you to build, ship and load `libllama.so` yourself anyway, the high-level wrapper has historically lagged llama.cpp API churn (e.g. the sampler-chain refactor), and pinning a specific upstream commit is awkward.
- **`fcllama` / `xuegao-tzx/Fllama`** uses a platform channel rather than FFI, which adds latency on the per-token streaming path and forfeits zero-copy.
- **`llamadart` (leehack)** is the newest entrant and structurally closest to what you want (Dart engine, isolate+FFI backend, web bridge), but it's young and you'd still be writing custom C glue for GPU backend selection.

**Decision: write a thin C wrapper around llama.cpp ourselves, generate Dart FFI bindings to that wrapper with `ffigen`, and vendor llama.cpp as a git submodule.** You get a pinned upstream commit, full control over `GGML_VULKAN` / `GGML_OPENCL` flags, a stable wrapper ABI that survives llama.cpp internal churn, easy KV-cache and sampler-chain access, and a single `.so` to ship. ffigen is bidirectional with C headers (`pubspec.yaml` → `ffigen` block → `dart run ffigen`), and modern Dart FFI's `NativeCallable.listener` (Dart ≥3.1) gives clean async token streaming from a worker thread back to the UI isolate without polling.

### 1.2 Native build: NDK r28, arm64-v8a only, CMake via AGP `externalNativeBuild`

- **NDK r28+** is required, not optional. NDK r28 compiles 16 KB-aligned by default. Per Google's *Transition to using 16 KB page sizes* blog, "Starting November 1st, 2025, all new apps and app updates that use native C/C++ code targeting Android 15+ devices submitted to Google Play must support 16 KB page sizes"; the wider enforcement window for existing apps was extended via an opt-in process to **31 May 2026** (per Google Play's "Clarification of the 16KB page size deadline" community post). NDK r27 and earlier need explicit `-Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384`. Just use r28+.
- **arm64-v8a only.** Don't waste APK bloat on `armeabi-v7a` (no devices in your target tier are 32-bit) or `x86_64` (only useful for emulator dev — keep a separate debug variant if you need it). Targeting `-DANDROID_PLATFORM=android-28` (Android 9.0) is the realistic minSdk; everything below has no Vulkan-capable GPU population worth supporting.
- Use `-DCMAKE_C_FLAGS="-march=armv8.2-a+dotprod+fp16"` rather than the stock llama.cpp Android docs' `armv8.7a` — armv8.7 only compiles correctly on a narrower SoC range and llama.cpp does runtime CPU-feature dispatch anyway.
- Build with `GGML_OPENMP=OFF`, `GGML_LLAMAFILE=OFF`, `BUILD_SHARED_LIBS=ON` (you want one `libllama.so` you can drop into `jniLibs/arm64-v8a/`).
- Wire CMake into Android Gradle Plugin via `android { externalNativeBuild { cmake { path = "src/main/cpp/CMakeLists.txt" } } }` so the build is reproducible from `flutter build apk` without out-of-band scripts.

### 1.3 GPU strategy: Vulkan primary, OpenCL fallback, runtime probe

This is the single most fragile area of the project. The honest current state on Android (May 2026):

- **Vulkan (`GGML_VULKAN=ON`)** in llama.cpp works on desktop and is excellent on Apple/AMD/NVIDIA, but on Android it is **community-supported only** — there is no official `docs/android.md` section for it, and the canonical reproductions show Adreno phones aborting inside `ggml_vk_create_pipeline()` (Issue #11327 on Adreno 710) and Mali phones running slower than CPU. Discussion #8874 contains the only authoritative workaround: build `vulkan-shaders-gen` for the **host** first, put it on `$PATH`, then run the Android cross-build so it doesn't try to cross-compile that helper for arm64-Android. Treat Vulkan as "works on some flagship Adrenos, breaks on others — build it but verify at runtime."
- **OpenCL (`GGML_OPENCL=ON`) on Adreno** is the **Qualcomm-endorsed path**. Per llama.cpp PR #10693 (Qualcomm engineer `lhez`, "Introducing experimental OpenCL backend with support for Qualcomm Adreno GPUs"), the backend was "tuned for and tested on the latest Snapdragon Gen 3, X-Elite, 8-Elite Android, Linux and Windows ARM64 platforms." The OPENCL.md verified-support table lists only two Android phone GPUs: **Adreno 750 (Snapdragon 8 Gen 3)** and **Adreno 830 (Snapdragon 8 Elite)**. The same doc warns "A6x GPUs in phones are likely not supported due to the outdated driver and compiler" — i.e. older Adrenos on phones are out. The build links against the Khronos `OpenCL-ICD-Loader` stub `libOpenCL.so` (built for arm64-Android, ANDROID_PLATFORM=24, c++_shared) at compile time; at runtime the ICD loader `dlopen()`s the OEM's `/vendor/lib64/libOpenCL.so`. Qualcomm's own integration story is `adb push` to `/data/local/tmp`, *not* APK packaging — bundling a stub `libOpenCL.so` in `jniLibs/arm64-v8a/` and relying on Android's linker namespace to resolve the vendor ICD via `/vendor/etc/OpenCL/vendors/*.icd` works on most Qualcomm devices but is undocumented for app-process use. You will hit cases where it doesn't load and must fall back to CPU.
- **Hexagon NPU (`GGML_HEXAGON=ON`)** — Qualcomm's upstream NPU backend, merged late 2025 (release b7519 onward), supports HTP arch v73 (Snapdragon 8 Gen 2), v75 (8 Gen 3), v79 (8 Elite), v81 (next-gen). **Skip it for v1.** It requires the proprietary Hexagon SDK at build time (gated behind a Qualcomm Developer account, current version 6.4.0.2), the cDSP libraries need to be `.cat`-signed to load on commercial devices, on-device session memory is capped at ~3.5 GB, and the only documented deployment flow is `adb push` to `/data/local/tmp`. **Not practically redistributable in a Play Store APK today.**
- **Vulkan compute** is part of the Android NDK sysroot from API 24 (Android 7.0). Vulkan 1.1+ devices are essentially universal at our minSdk; quality of the driver is the real variable.

**Decision tree at runtime:**
1. Try Vulkan. Probe by attempting to enumerate `VkPhysicalDevice`s and load a tiny test compute pipeline before loading any model. If init succeeds, use it with `n_gpu_layers = 99`.
2. If Vulkan init fails, try OpenCL. Detect by attempting to `clGetPlatformIDs` via the bundled ICD loader; if `> 0` platforms and the platform name matches `QUALCOMM`, use OpenCL with `n_gpu_layers = 99`. (For non-Qualcomm Adrenos or Mali, treat any non-Qualcomm OpenCL platform as a no.)
3. Fall back to CPU. Use ARM NEON + `Q4_0` repacked at load time (llama.cpp does this automatically on supported hardware) and threads = number of performance cores − 1.
4. Persist the result per-device in `SharedPreferences` so you don't re-probe every cold start, but expose a "force CPU/GPU" override in settings.

Bundle **both** `libllama.so` variants inside the APK if you can stomach the size — one built with `GGML_VULKAN=ON` only, one built with `GGML_OPENCL=ON` only — load whichever the probe selected via `dlopen` from a single Dart entry point. Bundling both flavours adds roughly 8–12 MB to the APK; this is acceptable for an app that's gated by users supplying a multi-gigabyte model anyway.

### 1.4 Threading and streaming model

Run all llama.cpp work on a **dedicated Dart isolate** (the "inference isolate"). Inside the wrapper, llama.cpp's own `n_threads` controls the *internal* CPU thread pool — that's separate from Dart isolates and is what does the actual decode work. The Dart isolate is the synchronisation primitive between FFI and the UI isolate.

Token streaming uses Dart 3.1's `NativeCallable.listener`: the C wrapper exposes a `start_generation(ctx, prompt, on_token_cb)` where `on_token_cb` is a function pointer the wrapper invokes once per token from the worker thread. The Dart side allocates a `NativeCallable<Void Function(Pointer<Char>, Int32)>.listener(_onToken)` and passes its `nativeFunction` over FFI. The listener marshals each token into a Dart `StreamController<String>` on the inference isolate, which forwards over a `SendPort` to the UI isolate's `Stream<ChatToken>`.

**Cancellation** uses `llama_set_abort_callback`. The C wrapper stores an `atomic_int cancel_flag` and the abort callback returns `cancel_flag != 0`. `cancel_generation()` flips the flag. This stops mid-prompt-processing as well as mid-decode (unlike naive `break`-out-of-loop approaches that only fire between tokens).

### 1.5 State management: Riverpod 3, with `riverpod_generator`

Riverpod 3 is the right default for a streaming chat app in 2026. It composes `StreamProvider` with `AsyncValue` cleanly for the token stream, makes provider overrides trivial for tests, and has no `BuildContext` coupling — important because you'll be reading state from background services. BLoC is the alternative if you want strict event-sourcing for audit; Provider is too thin; GetX is a maintenance liability and is correctly being abandoned by the community.

### 1.6 Persistence: Drift (SQLite)

Conversations are inherently relational (Conversation 1—N Message; Message N—M Attachment; Conversation N—1 ModelProfile). Drift gives compile-time-checked SQL, ACID transactions for atomic message+token-stream commits, FTS5 for conversation search, and predictable migrations. **Isar is out** because the original maintainer has gone silent and Isar v4 has stalled; betting an indie production app on it is a bad call in 2026. **ObjectBox** is fine technically but adds a commercial-license footgun. **Hive** is for shared-prefs replacements, not message history. **Drift** is the conservative choice and matches the developer's systems-programming background.

### 1.7 GGUF file access: SAF + persistable URI permissions, copy-on-import

Android 11+ scoped storage means you cannot `fopen()` a path the user picked from Downloads. Two options:

1. **Pick + copy into app-private storage** (`getFilesDir()/models/`). Pros: `mmap()` works directly, no SAF complexity at inference time, simple. Cons: doubles disk use during import (the user already has a 2.8 GB GGUF in Downloads, you copy it into your sandbox).
2. **Pick + persist URI with `takePersistableUriPermission`** then open via `ContentResolver.openFileDescriptor("r")` and pass the resulting fd into `mmap`. Pros: no copy. Cons: SAF document URIs in scoped storage on Android 11+ go through FUSE, which adds 10–30% mmap overhead and has historically been fragile for >1 GB files; some OEM file providers don't support seeking.

**Decision: copy-on-import to app-private storage.** It is unambiguously the correct call for this app: GGUFs are write-once-read-many, the user only does the import once per model, and once it's in `getFilesDir()` you get a real path, real `mmap`, no fragility. The model manager UI can show an "imported on / size" entry and offer delete. **Do not** request `MANAGE_EXTERNAL_STORAGE` — Google Play's policy is restrictive and there is no defensible justification when SAF + copy works.

### 1.8 Quantisation, context, and memory targets for Gemma 3n E2B

- Gemma 3n E2B has **5.44 B raw parameters** but operates with an effective ~2 B memory footprint for the active path thanks to MatFormer + Per-Layer Embeddings (PLE). In llama.cpp the model still loads as ~4 B params (the GGUF carries the full weights) — the `ggml-org/gemma-3n-E2B-it-GGUF` repo lists "Model size 4 B params, Architecture gemma3n".
- **`Q4_K_M` is the default ship quant.** The `bartowski/google_gemma-3n-E2B-it-GGUF` Q4_K_M file is **2.79 GB** on disk; with 4K context KV cache it lands at roughly 3.0–3.2 GB resident. `Q5_K_M` adds ~600 MB and is justifiable on 8 GB+ RAM devices. `IQ4_XS` is smaller (~2.3 GB) but loses noticeable quality on Gemma. Avoid `Q4_0` "pure" *unless* the user is on Adreno OpenCL where Qualcomm's own guidance is to quantise `--pure Q4_0` for best kernel performance; expose this as an "Adreno-optimised" GGUF preset in the model picker.
- **Context length: default 4096, allow 2048/4096/8192**. KV cache for Gemma 3n at 4K context is ~120–180 MB; at 8K it doubles. The model's training context is 32K but mobile RAM and prompt-processing latency make 4K the sweet spot.
- **Multimodal: text-only, period.** Despite Gemma 3n being natively multimodal (image + audio), llama.cpp only supports the **text** modality for Gemma 3n (Issue #14429, Discussion #15194 — both confirm the audio/vision encoders are not implemented). Don't promise vision. The official `ggml-org/gemma-3n-E2B-it-GGUF` model card states verbatim: "This version does not contain multimodal support. We are still working on adding multimodal."
- **Sampling defaults (Google's recommended):** `temperature=1.0`, `top_k=64`, `top_p=0.95`, `min_p=0.0`, `repeat_penalty=1.0`. Expose these as per-conversation overrides.
- **Chat template:** `<bos><start_of_turn>user\nHello!<end_of_turn>\n<start_of_turn>model\nHey there!<end_of_turn>\n`. llama.cpp auto-applies it from GGUF metadata when you call `llama_chat_apply_template`; just use that.

### 1.9 Background generation: foreground service of type `specialUse`

Android 14+ requires every foreground service to declare a type. There is no "AI" type; `dataSync` is wrong (it's for network sync); the correct choice is `foregroundServiceType="specialUse"` with `<property android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE" android:value="On-device LLM inference for an active user-initiated chat turn" />`. **You will need to justify this in Play Console review** — Google reviews `specialUse` declarations manually. Have your story ready: "Generation can take 30–90 seconds for long replies; the user must be able to switch to another app and return without losing the in-flight token stream."

Also declare `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_SPECIAL_USE` permissions, and acquire a partial `WAKE_LOCK` for the duration of generation only (not for the whole app session).

### 1.10 Non-obvious gotchas

- **The `vulkan-shaders-gen` cross-compile trap.** The Vulkan backend's CMake builds a host helper that compiles GLSL→SPIR-V at build time. With the NDK toolchain it will try to cross-compile that helper for arm64-Android and then "execute" it on your build host, which fails. Fix: build for host first (`cmake -B build-host -DGGML_VULKAN=ON && cmake --build build-host --target vulkan-shaders-gen`), then put `build-host/bin` on `$PATH` before invoking the Android CMake config. This is the only authoritative workaround in the upstream tracker (Discussion #8874).
- **16 KB page alignment is mandatory now**, not optional. Any `.so` you ship — including `libOpenCL.so` from the ICD loader — must be 16 KB-aligned. NDK r28+ does this by default; verify with `unzip` + `llvm-objdump -p libllama.so | grep LOAD` looking for `2**14` alignment.
- **Dart `NativeCallable.listener` only supports `void`-returning callbacks.** Design your token callback as `void on_token(Pointer<Utf8>, int len, int is_final)` — never have C expect a return value to decide whether to continue. Use the abort callback for that.
- **Gemma 3n's `add_shared_kv_layers` field bug** (now fixed in current GGUFs): older community conversions encoded it as float32 and tripped runtime engines. Use Unsloth's or `ggml-org/`'s GGUFs and document this in the README.
- **OpenCL on phone-class A6xx Adrenos is officially "likely not supported"** per llama.cpp's own `OPENCL.md`. The OPENCL.md verified-support table for Android lists only Adreno 750 (Snapdragon 8 Gen 3) and Adreno 830 (Snapdragon 8 Elite). Anything older: CPU only.
- **Don't bundle the vendor's `libOpenCL.so` from `/vendor/lib64`.** Bundle the Khronos ICD-Loader stub. The vendor lib is not redistributable and will hard-fail on non-Qualcomm devices.

---

## Part 2 — Development Todo List

This list assumes the basic Flutter project scaffold (`flutter create`) is done. Each task is scoped to be picked up by an AI coding agent (Claude Code, Cursor) without further clarification. Decision points are flagged **DECIDE**.

### Phase 0: Repo hygiene and tooling

1. Pin Flutter SDK in `pubspec.yaml` (`environment: sdk: '>=3.5.0 <4.0.0'`, `flutter: '>=3.24.0'`) and Dart 3.5+. Add `.fvmrc` if using FVM.
2. Add a top-level `Makefile` or `justfile` with targets: `fmt`, `analyze`, `test`, `build-native-host`, `build-native-android`, `bench`. Wire to CI later.
3. Add `.gitattributes` setting `*.gguf binary` and `.gitignore` excluding `*.gguf`, `build-host/`, `build-android/`.
4. Add `analysis_options.yaml` extending `package:flutter_lints/flutter.yaml` plus `flutter_riverpod_lint`, `custom_lint`, and `unawaited_futures: error`.

### Phase 1: Native build & FFI bindings

5. Add llama.cpp as a git submodule at `third_party/llama.cpp` pinned to a known-good tag (e.g. release `b9009` or later — verify it builds with `GGML_VULKAN=ON` and `GGML_OPENCL=ON` for arm64-v8a). Document the pinned tag in `third_party/README.md`.
6. Create `android/app/src/main/cpp/inference.h` declaring the C ABI we expose to Dart. Required functions:
   ```c
   typedef struct llm_ctx llm_ctx;
   typedef void (*llm_token_cb)(const char* token, int32_t len, int32_t is_final, void* user);

   llm_ctx*    llm_load_model(const char* gguf_path, int32_t n_gpu_layers, int32_t n_ctx,
                              int32_t n_threads, int32_t backend_hint,
                              char* err_buf, int32_t err_buf_len);
   void        llm_free_model(llm_ctx* ctx);
   int32_t     llm_apply_chat_template(llm_ctx* ctx, const char* messages_json,
                                       char* out, int32_t out_len);
   int32_t     llm_start_generation(llm_ctx* ctx, const char* prompt, int32_t max_tokens,
                                    float temperature, float top_p, int32_t top_k,
                                    float repeat_penalty, uint32_t seed,
                                    llm_token_cb cb, void* user);
   void        llm_cancel_generation(llm_ctx* ctx);
   int32_t     llm_get_kv_cache_used(llm_ctx* ctx);
   void        llm_get_metrics(llm_ctx* ctx, double* time_to_first_token_ms,
                               double* tokens_per_sec, int32_t* n_prompt_tokens,
                               int32_t* n_decoded);
   int32_t     llm_probe_backends(int32_t* out_vulkan_ok, int32_t* out_opencl_ok);
   const char* llm_version(void);
   ```
   `backend_hint`: 0=auto, 1=cpu, 2=vulkan, 3=opencl.
7. Implement `inference.cpp` in the same directory wrapping llama.cpp. It must: call `llama_backend_init()` once on first load; hold a `std::atomic<int> cancel_flag`; install `llama_set_abort_callback` returning `cancel_flag.load()`; build a sampler chain via `llama_sampler_chain_init` with top-k → top-p → temp → dist samplers (in that order); decode with `llama_decode` in a single-threaded loop on the calling thread; invoke the token callback with each detokenised piece. **DECIDE** whether to expose a separate `llm_continue_generation` for chat-cache reuse or rebuild the prompt every turn — recommend caching for v1.
8. Write `android/app/src/main/cpp/CMakeLists.txt` with three targets:
   - `llama` — the upstream library, configured with `GGML_OPENMP=OFF`, `GGML_LLAMAFILE=OFF`, `BUILD_SHARED_LIBS=ON`, `CMAKE_C_FLAGS=-march=armv8.2-a+dotprod+fp16+fp16fml`, and **either** `GGML_VULKAN=ON` **or** `GGML_OPENCL=ON` selected by a top-level CMake option `LLM_GPU_BACKEND` (default `OPENCL`).
   - `OpenCL` — built from `third_party/OpenCL-ICD-Loader` per llama.cpp's `docs/backend/OPENCL.md`, with `ANDROID_PLATFORM=24`, `ANDROID_STL=c++_shared`. Output `libOpenCL.so` placed alongside `libllama.so`.
   - `inference` — our wrapper, links against `llama` (and `OpenCL` when applicable), produces `libinference.so`.
9. Add a host-build helper script `scripts/build-vulkan-shaders-gen-host.sh` that runs `cmake -B build-host -DGGML_VULKAN=ON -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_BUILD_TOOLS=OFF . && cmake --build build-host --target vulkan-shaders-gen -j` in `third_party/llama.cpp`, then exports `PATH="$PWD/third_party/llama.cpp/build-host/bin:$PATH"`. Call this before any Android Vulkan build. Document this prominently in `BUILDING.md`.
10. Configure `android/app/build.gradle.kts` (or `.gradle`) to wire CMake into AGP:
    ```kotlin
    android {
        ndkVersion = "28.0.13004108"
        defaultConfig {
            ndk { abiFilters += listOf("arm64-v8a") }
            externalNativeBuild { cmake { arguments += listOf("-DANDROID_STL=c++_shared", "-DLLM_GPU_BACKEND=OPENCL") } }
        }
        externalNativeBuild { cmake { path = file("src/main/cpp/CMakeLists.txt"); version = "3.22.1" } }
        packaging { jniLibs { useLegacyPackaging = false } }
    }
    ```
    minSdk 28, targetSdk 35, compileSdk 35.
11. Build product flavours `gpuOpenCl` and `gpuVulkan` with different `LLM_GPU_BACKEND` values, producing two split APKs at `flutter build apk --flavor gpuOpenCl` etc. **DECIDE**: ship as a single APK with both `.so` files (~+10 MB) loaded by `dlopen` at runtime, *or* ship as separate App Bundles with Play Store device targeting. Recommend single APK for v1, split later if APK size becomes a Play Store warning.
12. Add `ffigen.yaml` at project root pointing at `android/app/src/main/cpp/inference.h`, output `lib/src/native/inference_bindings.dart`. Run `dart run ffigen` and commit the generated file. Add a CI check that regenerates it and fails if the diff is non-empty.
13. Add `lib/src/native/inference_loader.dart` that locates `libinference.so` via `DynamicLibrary.open('libinference.so')` on Android, with a separate desktop loader for `libinference.dylib`/`libinference.dll` for unit testing.

### Phase 2: Core inference plumbing

14. Create `lib/src/inference/inference_isolate.dart` spawning a long-lived `Isolate` running an inference engine. Use `Isolate.spawn` with two `SendPort`s: one for commands (load, generate, cancel), one for events (token, status, metrics, error). Reference Riverpod's `StateNotifier` patterns for command sequencing.
15. Inside the isolate, set up a `NativeCallable<Void Function(Pointer<Utf8>, Int32, Int32, Pointer<Void>)>.listener` for the token callback. The listener pushes `TokenEvent(text, isFinal)` into a `StreamController` whose stream is sent over the events `SendPort`.
16. Define the command/event sealed classes:
    ```dart
    sealed class InferenceCommand {}
    class LoadModelCommand extends InferenceCommand { final String path; final InferenceConfig config; }
    class GenerateCommand extends InferenceCommand { final String prompt; final SamplingParams sampling; final int maxTokens; }
    class CancelCommand extends InferenceCommand {}
    class UnloadCommand extends InferenceCommand {}

    sealed class InferenceEvent {}
    class ModelLoadedEvent extends InferenceEvent { final ModelMetadata metadata; }
    class ModelLoadFailedEvent extends InferenceEvent { final String message; }
    class TokenEvent extends InferenceEvent { final String token; }
    class GenerationDoneEvent extends InferenceEvent { final GenerationMetrics metrics; }
    class GenerationCancelledEvent extends InferenceEvent {}
    class GenerationErrorEvent extends InferenceEvent { final String message; }
    ```
17. Implement `InferenceService` (Dart side, owned by main isolate) that wraps the `SendPort` machinery and exposes a Dart-idiomatic API: `Future<void> loadModel(...)`, `Stream<TokenEvent> generate(...)`, `Future<void> cancel()`. `generate` returns a broadcast stream backed by the events `SendPort`.
18. Implement `BackendProbe.probe()` that calls `llm_probe_backends` once per app cold start and persists the result keyed by device fingerprint (Build.MODEL + Build.HARDWARE) in `SharedPreferences` so subsequent launches skip the probe.
19. Add `lib/src/inference/sampling_params.dart` with Gemma 3n defaults baked in: `temperature: 1.0, topK: 64, topP: 0.95, minP: 0.0, repeatPenalty: 1.0`. Provide a `SamplingParams.copyWith` for per-conversation overrides.
20. Add `lib/src/inference/chat_template.dart` that, on `ModelLoaded`, calls `llm_apply_chat_template` to verify the GGUF-embedded template is detected; if not, fall back to Gemma 3n's hardcoded template `<bos><start_of_turn>user\n{prompt}<end_of_turn>\n<start_of_turn>model\n`.

### Phase 3: GGUF metadata and model manager

21. Implement `lib/src/gguf/gguf_parser.dart` — a pure-Dart GGUF v3 reader. It must read only the header (`GGUF` magic, version u32, tensor_count u64, kv_count u64) and the KV pairs, **not** tensor data (~50 KB read for a 3 GB file). Extract: `general.architecture`, `general.name`, `general.size_label`, `general.quantization_version`, `general.parameter_count`, `general.file_type` (the quant code; map to human string Q4_K_M etc.), `gemma3n.context_length`, `gemma3n.embedding_length`, `gemma3n.block_count`, `tokenizer.chat_template`. Handle little-endian; refuse big-endian (v3 added it but Android is always LE).
22. Add `lib/src/models/gguf_metadata.dart` data class with the parsed fields, plus computed `prettyQuant`, `architectureFamily`, and `compatibilityWarning` (e.g. "Architecture 'gemma3n' detected — multimodal not supported in llama.cpp; text only").
23. Build the model import flow:
    - `lib/src/models/model_importer.dart`: uses `package:file_picker` (`FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['gguf'])`) to get a SAF URI, then streams 4 MB chunks via `ContentResolver.openInputStream` to `getFilesDir()/models/{uuid}.gguf` while emitting progress.
    - During import, parse the GGUF header on the source stream (first ~100 KB) to validate; reject non-GGUF or non-arm64-friendly architectures with a clear error.
    - On completion, write a sidecar `{uuid}.json` with the parsed metadata + original filename.
24. Implement `lib/src/models/model_repository.dart` (Riverpod `AsyncNotifierProvider<ModelRepository, List<ModelEntry>>`) backed by Drift table `model_entries(id, original_name, internal_path, size_bytes, sha256, imported_at, metadata_json)`.
25. Build the model manager UI screen `lib/src/ui/screens/model_manager_screen.dart`: list of imported models with name, quant badge, file size, import date, "set as active" radio, "delete" with confirmation. FAB triggers import flow with progress dialog. Expose total storage used / available.
26. Add a `ModelProfile` concept: per-model defaults for context length, GPU layers, sampling. Store in Drift `model_profiles(model_id, n_ctx, n_gpu_layers, system_prompt, sampling_json)`. Edit screen at `lib/src/ui/screens/model_settings_screen.dart`.

### Phase 4: Chat persistence and state

27. Define Drift schema in `lib/src/db/database.dart`:
    - `conversations(id, title, model_id, system_prompt, created_at, updated_at, archived)`
    - `messages(id, conversation_id, role, content, created_at, generation_metrics_json, parent_message_id)` — `parent_message_id` enables edit-and-resend branches.
    - `attachments(id, message_id, kind, path)` — future-proof for when llama.cpp adds Gemma 3n vision; v1 leaves it empty.
    - FTS5 virtual table `messages_fts` on `messages.content` with content sync triggers for in-app search.
28. Generate Drift code (`dart run build_runner build`) and commit. Add migrations from schema version 1 onward.
29. Build the chat repository `lib/src/chat/chat_repository.dart` exposing `Stream<List<Message>> watchMessages(conversationId)` (Drift's reactive query) and atomic `appendAssistantTokens(messageId, partialText)` updates that stream into the open assistant message row.
30. Set up Riverpod providers (`riverpod_generator`):
    - `@riverpod activeModelProvider` — currently selected model.
    - `@riverpod conversationsProvider` — list with last-message preview.
    - `@riverpod conversationMessagesProvider(int id)` — Stream of messages.
    - `@riverpod inferenceServiceProvider` — singleton `InferenceService`, keepAlive.
    - `@riverpod chatControllerProvider(int id)` — orchestrates user message → template → start_generation → token stream → DB writes → finalisation, with cancel support.
31. Implement edit-and-resend: when user edits an earlier message, fork the conversation tree at `parent_message_id`, replay history up to the edited turn, kick off a new generation. Show the new branch alongside the old in a collapsible UI.
32. Implement regenerate: discard the last assistant message (mark as `archived=true` in a sibling branch), re-run generation with the same prompt and a new seed.

### Phase 5: Chat UI

33. Build `lib/src/ui/screens/chat_screen.dart`: conversation list drawer + main pane with messages and a composer.
34. Implement message rendering with `flutter_markdown_plus` (or `flutter_markdown` if deprecated) for headings, lists, links. Use `flutter_highlight` with a Dart-side syntax highlighter for code blocks.
35. Each assistant message has actions: copy, regenerate, edit-and-branch, "stop" while streaming. User messages: copy, edit, delete-from-here.
36. Add the live-token rendering optimisation: don't rebuild the entire markdown tree on every token (it's quadratic). Instead, maintain a `ValueNotifier<String>` on the in-flight message and use `AnimatedBuilder` so only the trailing paragraph re-parses; switch to full markdown rendering once `GenerationDoneEvent` arrives.
37. Add a status bar at the bottom of the chat showing: active model name + quant, GPU backend in use (Vulkan/OpenCL/CPU badge), context utilisation `2 134 / 4 096`, and during generation: TTFT (ms) and live tok/s. Source these from `GenerationMetrics`.
38. Composer: multi-line `TextField` with Send button that disables during generation and converts to a Stop button. Long-press Send for a sampling-override sheet.
39. Build a per-conversation settings sheet exposing: system prompt (multi-line), context length (chips: 2k/4k/8k), n_gpu_layers (slider 0–99), temperature/top_p/top_k/repeat_penalty (sliders with the Gemma 3n defaults marked).
40. Add a "thinking" indicator that shows during prompt-processing (between submit and first token) — pulse the assistant bubble with "…thinking" text.

### Phase 6: Background handling, lifecycle, and polish

41. Create the foreground service in Kotlin: `android/app/src/main/kotlin/.../InferenceForegroundService.kt`. Implement `onStartCommand` calling `startForeground(NOTIF_ID, buildNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)`. The notification should be persistent, low-importance, with title "Generating reply…" and a Stop action.
42. Edit `AndroidManifest.xml` to add:
    ```xml
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <service android:name=".InferenceForegroundService"
             android:foregroundServiceType="specialUse"
             android:exported="false">
        <property android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
                  android:value="On-device LLM inference for an active user-initiated chat turn"/>
    </service>
    ```
43. Bridge Flutter ↔ service via a `MethodChannel` `app/inference_service` with methods `start(turnId)`, `updateProgress(tokensGenerated)`, `stop()`. The service does NOT run inference itself — the Dart isolate does. The service exists only to keep the process alive and surface a notification.
44. Acquire a partial `WAKE_LOCK` (`PowerManager.PARTIAL_WAKE_LOCK`) on `start`, release on `stop`. Tag it `app:llm-inference` so it's identifiable in `dumpsys power`.
45. Implement thermal monitoring: register a `PowerManager.OnThermalStatusChangedListener` (API 29+). On `THERMAL_STATUS_SEVERE` or worse, emit an event into the inference isolate that pauses generation (set the cancel flag) with a "thermal pause" reason; resume on `THERMAL_STATUS_LIGHT`. Surface in UI as a yellow banner.
46. Add settings screen `lib/src/ui/screens/settings_screen.dart` with: backend override (auto/cpu/vulkan/opencl), thread count override, a "run benchmark" button that calls into a Dart-side `bench()` function.
47. Implement on-device benchmark `lib/src/inference/bench.dart`: load the active model, run prompt-processing (pp512 — feed 512 tokens) and token-generation (tg128 — generate 128 tokens) with a fixed seed, record tok/s for each, persist to a `benchmarks` Drift table. Show last result in settings.
48. Add a "device compatibility" diagnostic: chip name (from `Build.HARDWARE`), total RAM, free RAM, available storage, detected GPU, Vulkan probe result, OpenCL probe result, `getconf PAGESIZE` (16 KB or 4 KB), Android version. Useful for bug reports.
49. Implement crash safety for the inference isolate: wrap each `llama_decode` call in a try/catch on the C side that writes the error to a buffer; on Dart side, if the isolate dies (`onExit` port fires unexpectedly), surface a "model crashed, please restart" banner instead of leaving the UI hung.

### Phase 7: Testing, benchmarking, and CI

50. Unit test the GGUF parser with three fixtures: a tiny hand-crafted GGUF v3 file with known KVs, a real Gemma 3n E2B Q4_K_M header (first 64 KB), and a malformed file (truncated, wrong magic).
51. Integration test the inference isolate using a tiny test model: **SmolLM2 360M Q4_K_M** (271 MB per `HuggingFaceTB/SmolLM2-360M-Instruct-GGUF`; alternatively SmolLM2 360M Q4_0 at 229 MB or IQ4_XS at 228 MB if you need to keep CI artefacts smaller). Loads in <2 s on a laptop. Assert: model loads, 32-token generation completes, cancellation aborts within 200 ms.
52. Add a second tiny test model option: Qwen 2.5 0.5B Q4_K_M for cases where you need a more capable smoke test.
53. Add an instrumented Android benchmark `androidTest/InferenceBenchmark.kt` using `androidx.benchmark` to measure cold-load time, TTFT, and tok/s for a fixed prompt across CPU/Vulkan/OpenCL backends. Run on a real Pixel 8 / Pixel 9 / Galaxy S24 in CI (Firebase Test Lab or self-hosted).
54. CI pipeline (GitHub Actions) jobs: (a) `flutter analyze` + `dart run ffigen --check`; (b) host-side Dart tests; (c) Android build (debug + release) producing AAB; (d) Play Console pre-launch report integration; (e) APK 16 KB alignment verifier (`unzip aab && llvm-objdump -p lib/arm64-v8a/*.so | grep LOAD | grep -v "2\*\*14"` should be empty).
55. Document the testing matrix in `TESTING.md`: minimum tested device list (Pixel 6a as low-bar, Pixel 8 Pro as Vulkan tier, OnePlus 13 / Snapdragon 8 Elite as OpenCL flagship, a Samsung Galaxy A-series as Mali fallback).

### Phase 8: Distribution and UK/EU compliance

56. Privacy posture: the app does no network IO during inference. Document this prominently in the README and the in-app About screen. The Play Console Data Safety form should declare zero data collection.
57. UK GDPR / EU AI Act: because all inference is on-device and no personal data is transmitted, the app is out of scope for most controller obligations, but note in the privacy policy that conversation logs are stored locally only and the user controls deletion. Provide an in-app "delete all conversations" and "delete all imported models" action.
58. License hygiene: llama.cpp is MIT, ggml is MIT — fine. The Khronos OpenCL ICD Loader is Apache 2.0 — fine. Gemma 3n's weights are under the **Gemma Terms of Use** (not OSI-open) — your app does not redistribute weights (user supplies the GGUF), so you don't bind yourself to those terms, but **link to the Gemma terms in the model manager** so the user knows what they're agreeing to when they download from Hugging Face. Add an in-app open-source attributions screen via `flutter_oss_licenses` or `package_info_plus`.
59. Play Console submission: declare `specialUse` foreground service with a written justification ("In-flight LLM token generation must continue when the user briefly switches apps; killing the process would discard up to 90 seconds of compute and the partially generated reply"). Expect manual review.
60. Add an in-app "Get a model" helper screen with deep links to `huggingface.co/ggml-org/gemma-3n-E2B-it-GGUF`, `huggingface.co/unsloth/gemma-3n-E2B-it-GGUF`, and `huggingface.co/bartowski/google_gemma-3n-E2B-it-GGUF`. Include a one-line warning that the user is downloading from a third party and should verify the SHA-256 (publish the expected hash for the recommended Q4_K_M file — for `bartowski/google_gemma-3n-E2B-it-GGUF` Q4_K_M that is `b29adbcff5e0458d8bfa0b26fe6acb2c722f9eaa84890995dfd394d24c236389`, 2.79 GB).

### Phase 9: Stretch / v1.1

61. KV-cache persistence: serialise the post-prompt KV cache to disk so reopening a long conversation skips prompt-processing. llama.cpp exposes `llama_state_get_data` / `llama_state_set_data`. Worth ~5–30 s per turn on long chats.
62. Speculative decoding with a draft model (e.g. SmolLM2 360M as draft for Gemma 3n E2B): not currently supported in upstream llama.cpp's main API for cross-arch drafts; revisit when it is.
63. Streaming markdown re-renderer: replace the `ValueNotifier` hack with a proper incremental markdown parser (none exist for Flutter; would have to write one).
64. Voice input via `speech_to_text` (system STT, not on-device). Voice output via `flutter_tts`. Position as accessibility, not a "Gemma 3n audio" feature (which llama.cpp doesn't support).

---

## Caveats

- **Vulkan on Adreno is unreliable**, full stop. Until either (a) Qualcomm contributes Vulkan-backend kernels equivalent to their OpenCL ones, or (b) Mesa-style mainline drivers ship on Adreno phones, expect a non-trivial fraction of users to fall back to OpenCL or CPU. Plan UX accordingly — don't promise "GPU acceleration" without qualification.
- **The Hexagon NPU backend is not viable for a Play Store app in 2026.** Re-evaluate when Qualcomm ships a non-SDK-gated build path and the cDSP signing requirement is relaxed for third-party apps.
- **Multimodal (vision/audio) on Gemma 3n via llama.cpp is text-only and likely to stay that way through 2026** — Issue #14429 has been open since the model launched and no PR is in flight. If the project requires multimodal, switch to MediaPipe / LiteRT-LLM as the inference backend (different stack, no GGUF, no llama.cpp).
- **Gemma 4 (E2B/E4B) was released on 2 April 2026** under the Apache 2.0 licence (per Wikipedia's *Gemma (language model)* article and Google DeepMind's launch post the same day) with explicit on-device targeting, image+audio support, 128K context, and a friendlier licence than Gemma 3n's. For a project starting now, **strongly consider Gemma 4 E2B as the primary target instead of Gemma 3n E2B** — same effective size, better quality, friendlier licence. Architecturally this todo list is identical (both are gemma3n-family GGUFs in llama.cpp); only the model URL changes. Gemma 4 GGUFs are at `unsloth/gemma-4-E2B-it-GGUF` and `ggml-org/gemma-4-E2B-it-GGUF`. Note Gemma 4 E2B/E4B also remain text-only in llama.cpp inference (Unsloth: "Currently Gemma 3n is only supported in text format for inference" — same constraint applies to the 3n-family heads in Gemma 4 E2B).
- **Performance expectations** for Gemma 3n E2B Q4_K_M on a Snapdragon 8 Gen 3 phone (extrapolated from llama.cpp Adreno OpenCL benchmarks and the OnePlus 13 / Snapdragon 8 Elite test cases): roughly 12–18 tok/s on CPU (8 threads), 20–30 tok/s on Adreno OpenCL, 5–10 tok/s on Vulkan when it works at all. TTFT for a 200-token prompt: 600–1200 ms. These are ballpark and will swing significantly with thermal state — benchmark on the developer's actual device early.
- **APK size with both libllama variants + Khronos ICD loader** lands around 25–35 MB before Flutter assets. That's fine. Adding `armeabi-v7a` would roughly double native-libs size for negligible user reach — don't.
- **The llama.cpp Vulkan path on Android is undocumented in upstream `docs/`** and entirely dependent on community discussion threads (most importantly #8874). Expect breakage on llama.cpp upgrades; pin the submodule and bump deliberately, with a real-device smoke test in the bump PR.