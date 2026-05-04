/// Sampling parameters for text generation.
///
/// Baked-in defaults follow Google's recommended Gemma 3n/E2B settings:
/// temperature=1.0, top_k=64, top_p=0.95, min_p=0.0, repeat_penalty=1.0.
class SamplingParams {
  const SamplingParams({
    this.temperature = 1.0,
    this.topK = 64,
    this.topP = 0.95,
    this.minP = 0.0,
    this.repeatPenalty = 1.0,
    this.seed = 0xFFFFFFFF, // LLAMA_DEFAULT_SEED
    this.maxTokens = 512,
  });

  final double temperature;
  final int topK;
  final double topP;
  final double minP;
  final double repeatPenalty;
  final int seed;
  final int maxTokens;

  SamplingParams copyWith({
    double? temperature,
    int? topK,
    double? topP,
    double? minP,
    double? repeatPenalty,
    int? seed,
    int? maxTokens,
  }) {
    return SamplingParams(
      temperature: temperature ?? this.temperature,
      topK: topK ?? this.topK,
      topP: topP ?? this.topP,
      minP: minP ?? this.minP,
      repeatPenalty: repeatPenalty ?? this.repeatPenalty,
      seed: seed ?? this.seed,
      maxTokens: maxTokens ?? this.maxTokens,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SamplingParams &&
      other.temperature == temperature &&
      other.topK == topK &&
      other.topP == topP &&
      other.minP == minP &&
      other.repeatPenalty == repeatPenalty &&
      other.seed == seed &&
      other.maxTokens == maxTokens;

  @override
  int get hashCode => Object.hash(
      temperature, topK, topP, minP, repeatPenalty, seed, maxTokens);

  @override
  String toString() =>
      'SamplingParams(t=$temperature, top_k=$topK, top_p=$topP, '
      'min_p=$minP, repeat=$repeatPenalty, seed=$seed, max_tokens=$maxTokens)';
}
