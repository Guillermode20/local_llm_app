/// Configuration for loading an inference model.
class InferenceConfig {
  const InferenceConfig({
    this.nGpuLayers = 0,
    this.nCtx = 4096,
    this.nThreads = 4,
    this.backendHint = BackendHint.auto,
  });

  /// Number of layers to offload to GPU (0 = CPU only, 99 = all).
  final int nGpuLayers;

  /// Context size (token count).
  final int nCtx;

  /// Number of CPU threads for llama.cpp internal thread pool.
  final int nThreads;

  /// GPU backend preference.
  final BackendHint backendHint;

  InferenceConfig copyWith({
    int? nGpuLayers,
    int? nCtx,
    int? nThreads,
    BackendHint? backendHint,
  }) {
    return InferenceConfig(
      nGpuLayers: nGpuLayers ?? this.nGpuLayers,
      nCtx: nCtx ?? this.nCtx,
      nThreads: nThreads ?? this.nThreads,
      backendHint: backendHint ?? this.backendHint,
    );
  }

  static const defaults = InferenceConfig();
}

/// GPU backend selection hint, matching the C ABI `backend_hint` parameter.
enum BackendHint {
  auto(0),
  cpu(1),
  vulkan(2),
  opencl(3);

  const BackendHint(this.value);
  final int value;
}
