#!/bin/bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BUILD_DIR="${1:-$THIS_DIR/build}"
AMDGPU_FAMILIES="${THEROCK_AMDGPU_FAMILIES:-gfx906}"
NPROC="$(nproc)"
LINK_JOBS="$((NPROC / 8 > 0 ? NPROC / 8 : 1))"

mkdir -p "$THIS_DIR/.ccache/therock"
eval "$("$THIS_DIR/build_tools/setup_ccache.py" \
  --dir "$(realpath "$THIS_DIR/.ccache/therock")" --init)"

cmake -S "$THIS_DIR" -B "$BUILD_DIR" -GNinja \
  -DTHEROCK_HIP_CPU_ONLY=ON \
  -DTHEROCK_AMDGPU_FAMILIES="$AMDGPU_FAMILIES" \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
  -DLLVM_PARALLEL_LINK_JOBS="$LINK_JOBS" \
  -DFLANG_PARALLEL_COMPILE_JOBS="$LINK_JOBS"

cmake --build "$BUILD_DIR" --parallel $(nproc) --target install
