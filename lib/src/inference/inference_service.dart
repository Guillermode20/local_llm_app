import 'dart:async';

import 'inference_command.dart';
import 'inference_config.dart';
import 'inference_event.dart';
import 'inference_isolate.dart';
import 'sampling_params.dart';

/// High-level Dart API for the inference engine.
///
/// Owns the inference isolate and exposes idiomatic Dart futures/streams.
/// All llama.cpp work runs on the dedicated isolate; this service lives
/// on the main isolate and communicates via [SendPort]s.
class InferenceService {
  InferenceIsolateHandles? _handles;

  /// State tracking for the current generation.
  StreamController<TokenEvent>? _tokenController;
  bool _generating = false;

  /// Whether a model is currently loaded.
  bool get isLoaded => _loaded;
  bool _loaded = false;

  /// Whether generation is in progress.
  bool get isGenerating => _generating;

  /// Guards against concurrent load/unload.
  bool _loading = false;
  bool _unloading = false;

  MetadataSnapshot? _lastMetadata;

  /// Start the inference isolate.
  Future<void> start() async {
    if (_handles != null) return;
    _handles = await spawnInferenceIsolate();

    // Subscribe to isolate exit so we can recover from crashes.
    _handles!.onExit.then((_) {
      _onIsolateDied();
    });
  }

  /// Load a model from [path] with the given [config].
  ///
  /// Returns when the model is loaded or fails with an error message.
  Future<void> loadModel(String path, InferenceConfig config) async {
    if (_loading) throw StateError('Already loading a model');
    if (_unloading) throw StateError('Currently unloading a model');
    _loading = true;

    try {
      await start();
      _ensureNotGenerating();

      final completer = Completer<void>();
      late StreamSubscription<dynamic> sub;

      sub = _handles!.eventPort.listen((event) {
        if (event is ModelLoadedEvent) {
          _loaded = true;
          _lastMetadata = MetadataSnapshot(
            nCtxTrain: event.metadata.nCtxTrain,
            nParams: event.metadata.nParams,
            name: event.metadata.name,
          );
          completer.complete();
          sub.cancel();
        } else if (event is ModelLoadFailedEvent) {
          _loaded = false;
          completer.completeError(Exception(event.message));
          sub.cancel();
        }
      });

      _handles!.commandPort.send(LoadModelCommand(path: path, config: config));
      await completer.future;
    } finally {
      _loading = false;
    }
  }

  /// Generate tokens from [prompt].
  ///
  /// Returns a broadcast stream of [TokenEvent]s. The stream completes
  /// when generation is done, cancelled, or errors.
  Stream<TokenEvent> generate(
    String prompt, {
    SamplingParams sampling = const SamplingParams(),
    int? maxTokens,
  }) {
    _ensureLoaded();
    if (_generating) {
      throw StateError('Generation already in progress');
    }
    _generating = true;

    _tokenController = StreamController<TokenEvent>.broadcast(
      onCancel: () {
        // If the stream is cancelled, cancel generation.
        cancel();
      },
    );

    late StreamSubscription<dynamic> sub;
    sub = _handles!.eventPort.listen((event) {
      if (event is TokenEvent) {
        _tokenController!.add(event);
      } else if (event is GenerationDoneEvent) {
        _generating = false;
        _lastMetadata = _lastMetadata?.copyWith(
          lastMetrics: GenerationMetrics(
            timeToFirstTokenMs: event.metrics.timeToFirstTokenMs,
            tokensPerSec: event.metrics.tokensPerSec,
            nPromptTokens: event.metrics.nPromptTokens,
            nDecoded: event.metrics.nDecoded,
          ),
        );
        _tokenController!.close();
        sub.cancel();
      } else if (event is GenerationCancelledEvent) {
        _generating = false;
        _tokenController!.close();
        sub.cancel();
      } else if (event is GenerationErrorEvent) {
        _generating = false;
        _tokenController!.addError(Exception(event.message));
        _tokenController!.close();
        sub.cancel();
      }
    });

    _handles!.commandPort.send(GenerateCommand(
      prompt: prompt,
      sampling: sampling,
      maxTokens: maxTokens,
    ));

    return _tokenController!.stream;
  }

  /// Cancel the current generation.
  Future<void> cancel() async {
    if (!_generating) return;
    _handles!.commandPort.send(const CancelCommand());
    // The cancel now works because generation runs on a native thread,
    // so the command port will be processed by the isolate's event loop
    // and llm_cancel_generation will set the atomic flag on the C side.
    // The polling timer detects the cancelled status and sends the event.
    // Give the C thread a brief window to notice the flag and stop.
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Unload the current model.
  Future<void> unloadModel() async {
    if (_unloading) throw StateError('Already unloading');
    if (!_loaded) return;
    _unloading = true;

    try {
      _ensureNotGenerating();

      final completer = Completer<void>();
      late StreamSubscription<dynamic> sub;

      sub = _handles!.eventPort.listen((event) {
        if (event is ModelLoadedEvent) {
          _loaded = false;
          completer.complete();
          sub.cancel();
        }
      });

      _handles!.commandPort.send(const UnloadModelCommand());
      await completer.future;
    } finally {
      _unloading = false;
    }
  }

  /// Get the last generation metrics snapshot.
  MetadataSnapshot? get lastMetadata => _lastMetadata;

  /// Dispose and shut down the inference isolate.
  Future<void> dispose() async {
    if (_tokenController != null && !_tokenController!.isClosed) {
      await _tokenController!.close();
    }
    if (_handles != null) {
      // Send ShutdownCommand and wait for the isolate to exit.
      _handles!.commandPort.send(const ShutdownCommand());
      await _handles!.onExit.timeout(const Duration(seconds: 3));
    }
    _handles = null;
    _loaded = false;
    _generating = false;
    _loading = false;
    _unloading = false;
  }

  // -------------------------------------------------------------------------
  // Crash recovery
  // -------------------------------------------------------------------------

  void _onIsolateDied() {
    _loaded = false;
    _generating = false;
    _loading = false;
    _unloading = false;
    _handles = null;

    // If there was a pending token controller, close it with an error.
    if (_tokenController != null && !_tokenController!.isClosed) {
      _tokenController!.addError(
        StateError('Inference engine crashed. Please reload the model.'),
      );
      _tokenController!.close();
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  void _ensureLoaded() {
    if (!_loaded) throw StateError('No model loaded');
  }

  void _ensureNotGenerating() {
    if (_generating) throw StateError('Generation in progress');
  }
}

/// Snapshot of model metadata and last generation metrics.
class MetadataSnapshot {
  const MetadataSnapshot({
    this.nCtxTrain = 0,
    this.nParams = 0,
    this.name,
    this.lastMetrics,
  });

  final int nCtxTrain;
  final int nParams;
  final String? name;
  final GenerationMetrics? lastMetrics;

  MetadataSnapshot copyWith({GenerationMetrics? lastMetrics}) {
    return MetadataSnapshot(
      nCtxTrain: nCtxTrain,
      nParams: nParams,
      name: name,
      lastMetrics: lastMetrics ?? this.lastMetrics,
    );
  }
}
