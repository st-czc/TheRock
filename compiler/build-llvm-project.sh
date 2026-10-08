#!/bin/bash
set -e

SRC="$PWD/llvm-project"

CMAKE_ARGS=(
  -G Ninja
  -S "$SRC/llvm"
  -B "$SRC/build"
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_INSTALL_PREFIX="$SRC/build/install"
  -DLLVM_ENABLE_PROJECTS="clang;lld;clang-tools-extra"
  -DLLVM_EXTERNAL_PROJECTS="NativeCPUPasses"
  -DLLVM_EXTERNAL_NATIVECPUPASSES_SOURCE_DIR="$SRC/../hipcpu-passes"
  -DLLVM_ENABLE_RUNTIMES="compiler-rt;libunwind;libcxx;libcxxabi"
  -DLLVM_TARGETS_TO_BUILD="AMDGPU;Native;SPIRV"
  -DLLVM_LINK_LLVM_DYLIB=ON
  -DLLVM_INCLUDE_TESTS=OFF
  -DLLVM_INCLUDE_EXAMPLES=OFF
  -DLLVM_INCLUDE_BENCHMARKS=OFF
)

cmake "${CMAKE_ARGS[@]}"

echo cmake --build "$SRC/build" --parallel $(nproc) --target install
