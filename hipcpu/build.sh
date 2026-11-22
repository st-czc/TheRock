#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BUILD_DIR="${1:-$ROOT_DIR/build}"
AMDGPU_FAMILIES="${THEROCK_AMDGPU_FAMILIES:-gfx906}"
NPROC="$(nproc)"
LINK_JOBS="$((NPROC / 8 > 0 ? NPROC / 8 : 1))"

mkdir -p "$ROOT_DIR/.ccache/therock"
eval "$("$ROOT_DIR/build_tools/setup_ccache.py" \
  --dir "$(realpath "$ROOT_DIR/.ccache/therock")" --init)"

cmake -S "$ROOT_DIR" -B "$BUILD_DIR" -GNinja \
  -DTHEROCK_HIP_CPU_ONLY=ON \
  -DTHEROCK_AMDGPU_FAMILIES="$AMDGPU_FAMILIES" \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
  -DLLVM_PARALLEL_LINK_JOBS="$LINK_JOBS" \
  -DFLANG_PARALLEL_COMPILE_JOBS="$LINK_JOBS"

cmake --build "$BUILD_DIR" --parallel $(nproc) --target install

STUB_DIR="$ROOT_DIR/install/lib/cmake/hsa-runtime64"
mkdir -p "$STUB_DIR"
if [ ! -f "$STUB_DIR/hsa-runtime64Config.cmake" ]; then
  touch "$STUB_DIR/hsa-runtime64Config.cmake"
fi
