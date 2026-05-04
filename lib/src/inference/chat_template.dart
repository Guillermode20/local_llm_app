import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'package:local_llm_app/src/native/inference_bindings.dart';

/// Hardcoded Gemma 3n/E2B fallback chat template for when the GGUF
/// does not contain one.
const kGemma3nFallbackTemplate =
    '<bos><start_of_turn>user\n{content}<end_of_turn>\n<start_of_turn>model\n';

/// Manually format a list of chat messages using the Gemma 3n template.
///
/// Used only when the GGUF has no embedded template and the C wrapper's
/// [llm_apply_chat_template] call fails.
String formatGemma3nChat({
  required List<Map<String, String>> messages,
}) {
  final buf = StringBuffer('<bos>');
  for (int i = 0; i < messages.length; i++) {
    final msg = messages[i];
    final role = msg['role'] ?? 'user';
    final content = msg['content'] ?? '';
    if (role == 'user') {
      buf.write('<start_of_turn>user\n$content<end_of_turn>\n');
    } else {
      buf.write('<start_of_turn>model\n$content<end_of_turn>\n');
    }
  }
  if (messages.isNotEmpty && messages.last['role'] == 'user') {
    buf.write('<start_of_turn>model\n');
  }
  return buf.toString();
}

/// Query the GGUF-embedded chat template via the C wrapper.
///
/// Returns the model's template string if found, or null if not available.
String? queryChatTemplate(Pointer<llm_ctx> ctx, InferenceBindings bindings) {
  final messagesJson = jsonEncode([
    {'role': 'user', 'content': ''},
  ]);
  final outBuf = calloc<Char>(4096);

  try {
    final result = bindings.llm_apply_chat_template(
      ctx,
      messagesJson.toNativeUtf8().cast<Char>(),
      outBuf,
      4096,
    );
    if (result > 0) {
      return outBuf.cast<Utf8>().toDartString(length: result);
    }
    return null;
  } finally {
    calloc.free(outBuf);
  }
}

/// Apply the chat template via the C wrapper.
///
/// [messages] should be a list of `{"role": "...", "content": "..."}` maps.
/// Returns the formatted prompt, or null on failure (falls back to
/// [formatGemma3nChat]).
///
/// Memory safety: the output buffer is allocated once and freed exactly once
/// in the outer `finally` block, even when the initial buffer is too small
/// and a reallocation is needed.
String? applyTemplate(
  Pointer<llm_ctx> ctx,
  InferenceBindings bindings, {
  required List<Map<String, String>> messages,
}) {
  final json = jsonEncode(messages);
  final jsonNative = json.toNativeUtf8().cast<Char>();
  final totalChars = json.length + messages.length * 128;
  final outSize = (totalChars * 2).clamp(1024, 32768);
  var outBuf = calloc<Char>(outSize);
  var result = -1;

  try {
    result = bindings.llm_apply_chat_template(
      ctx,
      jsonNative,
      outBuf,
      outSize,
    );

    // If the buffer was too small, reallocate with the required size.
    if (result > 0 && result > outSize) {
      calloc.free(outBuf);
      outBuf = calloc<Char>(result + 1);
      result = bindings.llm_apply_chat_template(
        ctx,
        jsonNative,
        outBuf,
        result + 1,
      );
    }

    if (result > 0) {
      return outBuf.cast<Utf8>().toDartString(length: result);
    }
    return null;
  } finally {
    calloc.free(outBuf);
    calloc.free(jsonNative);
  }
}
