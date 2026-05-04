import 'inference_config.dart';
import 'sampling_params.dart';

/// Commands sent to the inference isolate via its command SendPort.
sealed class InferenceCommand {
  const InferenceCommand();
}

class LoadModelCommand extends InferenceCommand {
  const LoadModelCommand({required this.path, required this.config});
  final String path;
  final InferenceConfig config;
}

class GenerateCommand extends InferenceCommand {
  const GenerateCommand({
    required this.prompt,
    this.sampling = const SamplingParams(),
    this.maxTokens,
  });
  final String prompt;
  final SamplingParams sampling;
  final int? maxTokens;
}

class CancelCommand extends InferenceCommand {
  const CancelCommand();
}

class UnloadModelCommand extends InferenceCommand {
  const UnloadModelCommand();
}

/// Gracefully shuts down the inference isolate, freeing all C resources.
class ShutdownCommand extends InferenceCommand {
  const ShutdownCommand();
}
