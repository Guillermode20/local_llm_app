/// Parsed GGUF metadata for a model file.
///
/// Extracts the essential fields from the GGUF header KV pairs.
/// All fields are nullable – the parser extracts what it can find.
class GgufMetadata {
  const GgufMetadata({
    this.architecture,
    this.name,
    this.sizeLabel,
    this.quantizationVersion,
    this.fileType,
    this.parameterCount,
    this.contextLength,
    this.embeddingLength,
    this.blockCount,
    this.chatTemplate,
  });

  /// e.g. "gemma3n", "llama", "qwen2"
  final String? architecture;

  /// e.g. "Gemma 3n E2B"
  final String? name;

  /// e.g. "4B"
  final String? sizeLabel;

  /// GGUF quantization version.
  final int? quantizationVersion;

  /// GGUF file type code (maps to quant like Q4_K_M, Q5_K_M, etc.).
  final int? fileType;

  /// Total parameter count.
  final int? parameterCount;

  /// Training context length in tokens.
  final int? contextLength;

  /// Embedding/hidden dimension size.
  final int? embeddingLength;

  /// Number of transformer blocks/layers.
  final int? blockCount;

  /// Chat template string from the GGUF metadata.
  final String? chatTemplate;

  /// Human-readable quantization label.
  String get prettyQuant {
    if (fileType == null) return 'Unknown';
    // GGUF file type constants from llama.cpp/gguf-py
    switch (fileType!) {
      case 0:
        return 'F32';
      case 1:
        return 'F16';
      case 2:
        return 'Q4_0';
      case 3:
        return 'Q4_1';
      case 4:
        return 'Q4_1 (4 bits, Q4_1)';
      case 6:
        return 'Q5_0';
      case 7:
        return 'Q5_1';
      case 8:
        return 'Q8_0';
      case 10:
        return 'Q2_K';
      case 11:
        return 'Q3_K_S';
      case 12:
        return 'Q3_K_M';
      case 13:
        return 'Q3_K_L';
      case 14:
        return 'Q4_K_S';
      case 15:
        return 'Q4_K_M';
      case 16:
        return 'Q5_K_S';
      case 17:
        return 'Q5_K_M';
      case 18:
        return 'Q6_K';
      case 19:
        return 'Q8_K (Q8_0 per tensor)';
      case 20:
        return 'IQ1_S';
      case 21:
        return 'IQ2_XXS';
      case 22:
        return 'IQ2_XS';
      case 23:
        return 'IQ3_XXS';
      case 24:
        return 'IQ1_M';
      case 25:
        return 'IQ4_NL';
      case 26:
        return 'IQ3_S';
      case 27:
        return 'IQ3_M';
      case 28:
        return 'IQ2_S';
      case 29:
        return 'IQ2_M';
      case 30:
        return 'IQ4_XS';
      case 31:
        return 'IQ3_XS';
      case 32:
        return 'IQ4_K_M (IQ4_NL + IQ4_XS)';
      case 33:
        return 'BF16';
      case 34:
        return 'Q4_0_4_4';
      case 35:
        return 'Q4_0_8_8';
      case 36:
        return 'Q4_0_4_8';
      default:
        return 'Type $fileType';
    }
  }

  /// Architecture family string (e.g. "gemma3n", "llama", "qwen2").
  String get architectureFamily {
    final arch = architecture ?? 'unknown';
    // Normalise known architectures
    if (arch.startsWith('gemma')) return 'gemma';
    if (arch.startsWith('llama')) return 'llama';
    if (arch.startsWith('qwen')) return 'qwen';
    if (arch.startsWith('mistral')) return 'mistral';
    if (arch.startsWith('falcon')) return 'falcon';
    if (arch.startsWith('phi')) return 'phi';
    if (arch.startsWith('starcoder')) return 'starcoder';
    if (arch.startsWith('deepseek')) return 'deepseek';
    return arch;
  }

  /// A compatibility note, or null if the model seems compatible.
  String? get compatibilityWarning {
    if (architecture == null) return 'Unknown architecture — may not work correctly';
    final arch = architecture!;
    if (arch == 'gemma3n') {
      return 'Gemma 3n family detected — multimodal (vision/audio) is not supported in llama.cpp; text only.';
    }
    if (arch == 'gemma' || arch == 'gemma2') {
      return 'Gemma 1/2 architecture — ensure you are using a compatible GGUF.';
    }
    return null;
  }

  /// A formatted size label with parameters (e.g. "4.0B params").
  String get prettyParamCount {
    if (parameterCount == null) return sizeLabel ?? 'Unknown';
    final count = parameterCount!;
    if (count >= 1000000000) {
      return '${(count / 1000000000).toStringAsFixed(1)}B params';
    } else if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M params';
    }
    return '$count params';
  }

  /// Human-readable file size estimate from context length.
  String? get estimatedMemoryUse {
    if (contextLength == null) return null;
    final layers = blockCount ?? 32;
    return '~${_formatMemory(contextLength! * layers * 128 * 2)}';
  }

  static String _formatMemory(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }

  @override
  String toString() =>
      'GgufMetadata(arch=$architecture, name=$name, quant=$prettyQuant, '
      'params=$prettyParamCount, n_ctx=$contextLength)';
}
