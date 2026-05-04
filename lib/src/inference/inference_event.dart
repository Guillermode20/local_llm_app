/// Events emitted by the inference isolate to the main isolate.
sealed class InferenceEvent {
  const InferenceEvent();
}

class ModelLoadedEvent extends InferenceEvent {
  const ModelLoadedEvent({required this.metadata});
  final ModelMetadata metadata;
}

class ModelLoadFailedEvent extends InferenceEvent {
  const ModelLoadFailedEvent({required this.message});
  final String message;
}

class TokenEvent extends InferenceEvent {
  const TokenEvent({required this.token, this.isFinal = false});
  final String token;
  final bool isFinal;
}

class GenerationDoneEvent extends InferenceEvent {
  const GenerationDoneEvent({required this.metrics});
  final GenerationMetrics metrics;
}

class GenerationCancelledEvent extends InferenceEvent {
  const GenerationCancelledEvent();
}

class GenerationErrorEvent extends InferenceEvent {
  const GenerationErrorEvent({required this.message});
  final String message;
}

/// Metadata about a loaded model, extracted from GGUF or C wrapper.
class ModelMetadata {
  const ModelMetadata({
    this.architecture,
    this.name,
    this.description,
    this.nParams = 0,
    this.nCtxTrain = 0,
    this.nEmbed = 0,
    this.nLayer = 0,
    this.fileType,
    this.chatTemplate,
  });

  final String? architecture;
  final String? name;
  final String? description;
  final int nParams;
  final int nCtxTrain;
  final int nEmbed;
  final int nLayer;
  final String? fileType;
  final String? chatTemplate;
}

/// Metrics from a completed generation.
class GenerationMetrics {
  const GenerationMetrics({
    this.timeToFirstTokenMs = 0.0,
    this.tokensPerSec = 0.0,
    this.nPromptTokens = 0,
    this.nDecoded = 0,
  });

  final double timeToFirstTokenMs;
  final double tokensPerSec;
  final int nPromptTokens;
  final int nDecoded;
}
