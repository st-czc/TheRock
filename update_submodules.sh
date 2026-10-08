#!/bin/bash
# Initialize and update the submodules used by the HIP CPU build.

set -euo pipefail

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SUBMODULES=(
  base/rocm-cmake
  compiler/amd-llvm
  compiler/hipcpu-passes
  compiler/llvm-project
  compiler/spirv-llvm-translator
  rocm-systems
)

git -C "$THIS_DIR" submodule sync -- "${SUBMODULES[@]}"
git -C "$THIS_DIR" submodule update --init --depth=1 --recommend-shallow -- "${SUBMODULES[@]}"
