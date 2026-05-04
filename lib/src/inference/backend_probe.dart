import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'package:local_llm_app/src/native/inference_bindings.dart';

/// Result of probing available GPU backends.
class BackendProbeResult {
  const BackendProbeResult({
    this.vulkanAvailable = false,
    this.openclAvailable = false,
    this.probeOk = false,
  });

  final bool vulkanAvailable;
  final bool openclAvailable;
  final bool probeOk;

  bool get anyGpu => vulkanAvailable || openclAvailable;
}

/// Probe available GPU backends via the C wrapper's [llm_probe_backends].
BackendProbeResult probeBackends(InferenceBindings bindings) {
  final vk = calloc<Int32>(1);
  final cl = calloc<Int32>(1);

  try {
    final ret = bindings.llm_probe_backends(vk, cl);
    return BackendProbeResult(
      vulkanAvailable: vk.value != 0,
      openclAvailable: cl.value != 0,
      probeOk: ret == 0,
    );
  } finally {
    calloc.free(vk);
    calloc.free(cl);
  }
}
