import 'dart:ffi';
import 'dart:io' show Platform;

import 'package:local_llm_app/src/native/inference_bindings.dart';

DynamicLibrary openInferenceLibrary() {
  if (Platform.isAndroid) {
    return DynamicLibrary.open('libinference.so');
  }

  if (Platform.isIOS || Platform.isMacOS) {
    return DynamicLibrary.process();
  }

  if (Platform.isWindows) {
    return DynamicLibrary.open('inference.dll');
  }

  if (Platform.isLinux) {
    return DynamicLibrary.open('libinference.so');
  }

  return DynamicLibrary.process();
}

InferenceBindings openInferenceBindings() {
  return InferenceBindings(openInferenceLibrary());
}
