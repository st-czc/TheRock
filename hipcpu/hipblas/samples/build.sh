#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

ROOT="$(cd ../../.. && pwd)"
TOOLCHAIN="$ROOT/install"
CLANGXX="$TOOLCHAIN/lib/llvm/bin/clang++"

mkdir -p out

for name in hip_axpy hip_gemm; do
  "$CLANGXX" -x hip --offload-arch=spvcpu \
    -I "$TOOLCHAIN/include" \
    "$name.cpp" \
    -L "$TOOLCHAIN/lib" -lhipblas -lrocblas \
    -o "out/$name"
done

echo "run with: LD_LIBRARY_PATH=$TOOLCHAIN/lib out/hip_axpy"
