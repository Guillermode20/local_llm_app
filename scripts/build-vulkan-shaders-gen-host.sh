#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
llama_root="$repo_root/third_party/llama.cpp"

cmake -S "$llama_root" -B "$llama_root/build-host" \
  -DGGML_VULKAN=ON \
  -DLLAMA_BUILD_TESTS=OFF \
  -DLLAMA_BUILD_EXAMPLES=OFF \
  -DLLAMA_BUILD_TOOLS=OFF

cmake --build "$llama_root/build-host" --target vulkan-shaders-gen -j

export PATH="$llama_root/build-host/bin:$PATH"