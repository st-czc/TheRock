#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Build hipBLAS for the HIP-CPU backend. Produces librocblas.so and libhipblas.so.
# The BLAS math functions return rocblas_status_not_implemented.
#
# Requires:
# 1. The HIP-CPU toolchain at $ROOT/install.
# 2. rocm-libraries at $ROOT/rocm-libraries.
# 3. The BUILD_HOST_ONLY patch in $ROOT/rocm-libraries/projects/rocblas/library/src/CMakeLists.txt.

ROOT="$(cd ../.. && pwd)"
TOOLCHAIN="$ROOT/install"
SRC="$ROOT/rocm-libraries/projects"
OUT="$PWD"
PREFIX="$ROOT/install"
CXX="$TOOLCHAIN/lib/llvm/bin/clang++"
CMAKEBUILDTOOLS="$TOOLCHAIN/share/rocmcmakebuildtools/cmake"

mkdir -p "$OUT" "$PREFIX"

# 1. Generate the BLAS function stubs.
python3 -I "$OUT/gen_rocblas_stubs.py"

common_args=(
  -GNinja
  -DCMAKE_CXX_COMPILER="$CXX"
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_PREFIX_PATH="$TOOLCHAIN"
  -DROCmCMakeBuildTools_DIR="$CMAKEBUILDTOOLS"
  -DCMAKE_INSTALL_PREFIX="$PREFIX"
)

# 2. Build hipblas-common.
cmake -B "$OUT/build/hipblas-common" "${common_args[@]}" "$SRC/hipblas-common"
cmake --build "$OUT/build/hipblas-common" --target install

# 3. Build rocblas.
cmake -B "$OUT/build/rocblas" "${common_args[@]}" \
  -DROCM_PATH="$TOOLCHAIN" \
  -DHIP_PLATFORM=amd \
  -DGPU_TARGETS=spvcpu \
  -DBUILD_WITH_TENSILE=OFF \
  -DBUILD_WITH_HIPBLASLT=OFF \
  -DBUILD_OFFLOAD_COMPRESS=OFF \
  -DBUILD_CLIENTS_TESTS=OFF -DBUILD_CLIENTS_SAMPLES=OFF -DBUILD_CLIENTS_BENCHMARKS=OFF \
  -DBUILD_HOST_ONLY=ON \
  -DROCBLAS_HOST_ONLY_STUBS="$OUT/rocblas_stubs.cpp" \
  "$SRC/rocblas"
cmake --build "$OUT/build/rocblas" --target rocblas
cmake --install "$OUT/build/rocblas"

# 4. Build hipblas.
cmake -B "$OUT/build/hipblas" "${common_args[@]}" \
  -DCMAKE_PREFIX_PATH="$PREFIX" \
  -DROCM_PATH="$PREFIX" \
  -DHIP_DIR="$TOOLCHAIN" \
  -DHIP_PLATFORM=amd \
  -DGPU_TARGETS=spvcpu \
  -DBUILD_WITH_SOLVER=OFF \
  -DBUILD_CLIENTS_TESTS=OFF -DBUILD_CLIENTS_SAMPLES=OFF -DBUILD_CLIENTS_BENCHMARKS=OFF \
  "$SRC/hipblas"
cmake --build "$OUT/build/hipblas" --target hipblas
cmake --install "$OUT/build/hipblas"

echo "Done: $PREFIX/lib/librocblas.so and $PREFIX/lib/libhipblas.so"
