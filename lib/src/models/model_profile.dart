import '../inference/inference_config.dart';
import '../inference/sampling_params.dart';

/// Per-model configuration profile.
///
/// Stores the default settings for a specific model, including context
/// length, GPU layers, system prompt, and sampling overrides.
class ModelProfile {
  const ModelProfile({
    this.nCtx = 4096,
    this.nGpuLayers = 0,
    this.systemPrompt,
    this.samplingParams,
  });

  /// Default context length for this model.
  final int nCtx;

  /// Default number of GPU layers (0 = CPU only).
  final int nGpuLayers;

  /// Optional system prompt to prepend to every conversation.
  final String? systemPrompt;

  /// Optional sampling parameter overrides.
  final SamplingParams? samplingParams;

  /// Merge with [config] to produce effective inference settings.
  InferenceConfig toInferenceConfig({required BackendHint backendHint}) {
    return InferenceConfig(
      nGpuLayers: nGpuLayers,
      nCtx: nCtx,
      backendHint: backendHint,
    );
  }

  /// Merge with defaults to produce effective sampling params.
  SamplingParams get effectiveSamplingParams =>
      samplingParams ?? const SamplingParams();

  ModelProfile copyWith({
    int? nCtx,
    int? nGpuLayers,
    String? systemPrompt,
    SamplingParams? samplingParams,
    bool clearSystemPrompt = false,
    bool clearSamplingParams = false,
  }) {
    return ModelProfile(
      nCtx: nCtx ?? this.nCtx,
      nGpuLayers: nGpuLayers ?? this.nGpuLayers,
      systemPrompt: clearSystemPrompt ? null : (systemPrompt ?? this.systemPrompt),
      samplingParams:
          clearSamplingParams ? null : (samplingParams ?? this.samplingParams),
    );
  }

  Map<String, dynamic> toJson() => {
        'n_ctx': nCtx,
        'n_gpu_layers': nGpuLayers,
        if (systemPrompt != null) 'system_prompt': systemPrompt,
        if (samplingParams != null)
          'sampling': {
            'temperature': samplingParams!.temperature,
            'top_k': samplingParams!.topK,
            'top_p': samplingParams!.topP,
            'min_p': samplingParams!.minP,
            'repeat_penalty': samplingParams!.repeatPenalty,
            'seed': samplingParams!.seed,
            'max_tokens': samplingParams!.maxTokens,
          },
      };

  factory ModelProfile.fromJson(Map<String, dynamic> json) {
    return ModelProfile(
      nCtx: (json['n_ctx'] as num?)?.toInt() ?? 4096,
      nGpuLayers: (json['n_gpu_layers'] as num?)?.toInt() ?? 0,
      systemPrompt: json['system_prompt'] as String?,
      samplingParams: json['sampling'] != null
          ? SamplingParams(
              temperature:
                  (json['sampling']['temperature'] as num?)?.toDouble() ?? 1.0,
              topK: (json['sampling']['top_k'] as num?)?.toInt() ?? 64,
              topP: (json['sampling']['top_p'] as num?)?.toDouble() ?? 0.95,
              minP: (json['sampling']['min_p'] as num?)?.toDouble() ?? 0.0,
              repeatPenalty:
                  (json['sampling']['repeat_penalty'] as num?)?.toDouble() ?? 1.0,
              seed: (json['sampling']['seed'] as num?)?.toInt() ?? 0xFFFFFFFF,
              maxTokens: (json['sampling']['max_tokens'] as num?)?.toInt() ?? 512,
            )
          : null,
    );
  }

  static const defaults = ModelProfile();
}
