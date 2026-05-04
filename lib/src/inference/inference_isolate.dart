import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'package:local_llm_app/src/native/inference_bindings.dart';
import 'package:local_llm_app/src/native/inference_loader.dart';

import 'inference_command.dart';
import 'inference_config.dart';
import 'inference_event.dart';
import 'sampling_params.dart';

/// Handles for communicating with a spawned inference isolate.
class InferenceIsolateHandles {
  const InferenceIsolateHandles({
    required this.commandPort,
    required this.eventPort,
    required this.onExit,
  });

  final SendPort commandPort;
  final ReceivePort eventPort;
  final Future<void> onExit;
}

/// Spawn a long-lived Dart isolate that owns all llama.cpp FFI state.
Future<InferenceIsolateHandles> spawnInferenceIsolate() async {
  final commandReceive = ReceivePort();
  final eventReceive = ReceivePort();
  final exitReceive = ReceivePort();

  final bindings = openInferenceBindings();

  await Isolate.spawn(
    _entryPoint,
    _IsolateArgs(
      commandCap: commandReceive.sendPort,
      eventSink: eventReceive.sendPort,
      exitSink: exitReceive.sendPort,
      bindings: bindings,
    ),
    onExit: exitReceive.sendPort,
  );

  return InferenceIsolateHandles(
    commandPort: await commandReceive.first as SendPort,
    eventPort: eventReceive,
    onExit: exitReceive.first.then((_) {}),
  );
}

// ---------------------------------------------------------------------------
// Isolate entry
// ---------------------------------------------------------------------------

class _IsolateArgs {
  const _IsolateArgs({
    required this.commandCap,
    required this.eventSink,
    required this.exitSink,
    required this.bindings,
  });

  final SendPort commandCap;
  final SendPort eventSink;
  final SendPort exitSink;
  final InferenceBindings bindings;
}

/// Isolate-local globals used by the C-invoked token callback.
Pointer<llm_ctx>? _gCtx;
InferenceBindings? _gBindings;

/// Global reference to the token [NativeCallable] so it is not GC'd.
NativeCallable<llm_token_cbFunction>? _gTokenCallable;

/// Global SendPort for forwarding [TokenEvent]s from the C callback.
SendPort? _gEventSink;

/// Timer for polling async generation completion.
Timer? _gPollTimer;

void _entryPoint(_IsolateArgs args) {
  _gEventSink = args.eventSink;
  _gBindings = args.bindings;

  // Create the token callback NativeCallable once and keep it alive.
  _gTokenCallable = NativeCallable<llm_token_cbFunction>.listener(_onToken);

  final commandPort = ReceivePort();
  args.commandCap.send(commandPort.sendPort);

  commandPort.listen((msg) {
    if (msg is InferenceCommand) {
      _handle(msg);
    }
  });
}

// ---------------------------------------------------------------------------
// Command dispatch
// ---------------------------------------------------------------------------

void _handle(InferenceCommand command) {
  switch (command) {
    case LoadModelCommand(:final path, :final config):
      _loadModel(path, config);

    case GenerateCommand(:final prompt, :final sampling, :final maxTokens):
      _generate(prompt, sampling, maxTokens);

    case CancelCommand():
      _cancelGeneration();

    case UnloadModelCommand():
      _unloadModel();

    case ShutdownCommand():
      _shutdown();
  }
}

// ---------------------------------------------------------------------------
// Load model
// ---------------------------------------------------------------------------

void _loadModel(String path, InferenceConfig config) {
  final bindings = _gBindings!;
  final errBuf = calloc<Char>(512);
  final pathNative = path.toNativeUtf8().cast<Char>();

  try {
    final ctx = bindings.llm_load_model(
      pathNative,
      config.nGpuLayers,
      config.nCtx,
      config.nThreads,
      config.backendHint.value,
      errBuf,
      512,
    );

    if (ctx == nullptr) {
      _gEventSink?.send(ModelLoadFailedEvent(
        message: errBuf.cast<Utf8>().toDartString(),
      ));
      return;
    }

    _gCtx = ctx;
    _gEventSink?.send(const ModelLoadedEvent(metadata: ModelMetadata()));
  } finally {
    calloc.free(errBuf);
    calloc.free(pathNative);
  }
}

// ---------------------------------------------------------------------------
// Generate (async — uses native thread under the hood)
// ---------------------------------------------------------------------------

void _generate(String prompt, SamplingParams sampling, int? maxTokensOverride) {
  final bindings = _gBindings!;
  final ctx = _gCtx;
  if (ctx == null) {
    _gEventSink?.send(const GenerationErrorEvent(message: 'No model loaded'));
    return;
  }

  final callable = _gTokenCallable!;
  final promptNative = prompt.toNativeUtf8().cast<Char>();
  final userData = calloc<IntPtr>(1).cast<Void>();

  // Launch generation on a native thread (non-blocking).
  final result = bindings.llm_start_generation_async(
    ctx,
    promptNative,
    maxTokensOverride ?? sampling.maxTokens,
    sampling.temperature,
    sampling.topP,
    sampling.topK,
    sampling.repeatPenalty,
    sampling.seed,
    callable.nativeFunction,
    userData,
  );

  // Free the prompt native string immediately — the C thread
  // copies it into its own std::string during thread startup.
  calloc.free(promptNative);

  if (result != 0) {
    calloc.free(userData);
    _gEventSink?.send(const GenerationErrorEvent(
        message: 'Failed to start generation'));
    return;
  }

  // Poll for completion with a periodic timer.
  // The timer yields to the event loop between ticks, which allows
  // CancelCommand and other messages to be processed.
  _gPollTimer?.cancel();
  _gPollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
    final status = bindings.llm_get_generation_status(ctx);

    if (status == 0 || status == 1) {
      // IDLE (shouldn't happen during gen) or RUNNING — keep polling.
      return;
    }

    // Generation finished — stop polling.
    _gPollTimer?.cancel();
    _gPollTimer = null;

    try {
      switch (status) {
        case 3: // CANCELLED
          calloc.free(userData);
          _gEventSink?.send(const GenerationCancelledEvent());
          return;
        case 4: // ERROR
          calloc.free(userData);
          _gEventSink?.send(const GenerationErrorEvent(
              message: 'Generation failed'));
          return;
        default:
          break; // DONE (2) — read metrics
      }

      // Read metrics (protected by try/finally for memory safety).
      final ttft = calloc<Double>(1);
      final tokps = calloc<Double>(1);
      final nPrompt = calloc<Int32>(1);
      final nDec = calloc<Int32>(1);

      try {
        bindings.llm_get_metrics(ctx, ttft, tokps, nPrompt, nDec);

        _gEventSink?.send(GenerationDoneEvent(
          metrics: GenerationMetrics(
            timeToFirstTokenMs: ttft.value,
            tokensPerSec: tokps.value,
            nPromptTokens: nPrompt.value,
            nDecoded: nDec.value,
          ),
        ));
      } finally {
        calloc.free(ttft);
        calloc.free(tokps);
        calloc.free(nPrompt);
        calloc.free(nDec);
        calloc.free(userData);
      }
    } catch (_) {
      // If sending fails (e.g. main isolate exited), just clean up.
      _gPollTimer?.cancel();
      _gPollTimer = null;
    }
  });
}

// ---------------------------------------------------------------------------
// Cancel generation
// ---------------------------------------------------------------------------

void _cancelGeneration() {
  final b = _gBindings;
  final ctx = _gCtx;
  if (b != null && ctx != null) {
    b.llm_cancel_generation(ctx);
  }
  // Don't send GenerationCancelledEvent here — the polling timer will
  // detect the cancelled status and send it once the thread has stopped.
}

// ---------------------------------------------------------------------------
// Token callback (invoked from C native thread, posted to this isolate)
// ---------------------------------------------------------------------------

void _onToken(Pointer<Char> token, int len, int isFinal, Pointer<Void> _) {
  final str = (len > 0) ? token.cast<Utf8>().toDartString(length: len) : '';
  _gEventSink?.send(TokenEvent(token: str, isFinal: isFinal != 0));
}

// ---------------------------------------------------------------------------
// Unload model
// ---------------------------------------------------------------------------

void _unloadModel() {
  _gPollTimer?.cancel();
  _gPollTimer = null;

  final bindings = _gBindings!;
  final ctx = _gCtx;
  if (ctx != null) {
    bindings.llm_free_model(ctx);
    _gCtx = null;
  }
  _gEventSink?.send(const ModelLoadedEvent(metadata: ModelMetadata()));
}

// ---------------------------------------------------------------------------
// Shutdown
// ---------------------------------------------------------------------------

void _shutdown() {
  _gPollTimer?.cancel();
  _gPollTimer = null;

  final bindings = _gBindings!;
  final ctx = _gCtx;
  if (ctx != null) {
    bindings.llm_free_model(ctx);
    _gCtx = null;
  }

  // Close the command port to allow the isolate to exit.
  // The event port will be GC'd on the main isolate side.
}
