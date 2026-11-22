# HIP on CPU

A [TheRock](https://github.com/ROCm/TheRock)-based build of HIP that runs on
CPUs via the [SYCL Native CPU
passes](https://github.com/intel/llvm/blob/sycl/sycl/doc/design/SYCLNativeCPU.md).

This is an experimental implementation of HIP on CPU —
not a production-ready HIP compiler and runtime.

## Build and Use

Fetch the compiler, runtime, and library submodules at their pinned commits.

```sh
./hipcpu/update_submodules.sh
```

Configure, build, and install the toolchain to `install/`.

```sh
./hipcpu/build.sh
```

Compile HIP programs with `hipcc`, then run them against the installed runtime.

```sh
install/bin/hipcc foo.cpp -o foo
LD_LIBRARY_PATH=install/lib ./foo
```

`hipcc` behaves like a regular HIP compiler, and CMake-based builds work as
usual.

## Overview

HIP source mixes host code and device code. LLVM's HIP offload compiles them
separately and bundles the device image into the host binary.

1. The host code compiles to a host object.
2. The device code:
   - compiles to LLVM bitcode for target `spvcpu-unknown-hipcpu`;
   - links with the device bitcode libraries;
   - lowers the SIMT semantics through the Native CPU passes;
   - compiles into a shared library as the device image.
3. The device image is bundled into the host object.
4. The host object links into the executable.
5. At runtime, the CPU backend dlopens the device image and runs kernels on a
   thread pool.

## Components

`compiler/llvm-project` — mainline LLVM/Clang, extended with the
`spvcpu-unknown-hipcpu` target triple. It implements the HIPCPU toolchain and
registers `spvcpu` (a virtual CPU architecture) as a HIP offload architecture
within LLVM's HIP offload framework. HIP device code compiles directly to CPU
LLVM IR, then the Native CPU passes handle its SIMT semantics, producing a
Linux shared library.

`compiler/hipcpu-passes` — an out-of-tree LLVM pass plugin, pruned out of
intel/llvm's SYCL Native CPU backend and extended for HIP.
The passes lower SIMT device code to vectorized, looped host code.
The HIP related passes emit the HSA metadata note the runtime reads,
and handle dynamic `__shared__`, `__constant__`/`__device__`,
and the HIP/AMDGPU builtins.

`compiler/amd-llvm/amd/device-libs` — the ROCm device libraries,
built for the spvcpu target.
Provides `oclc.bc`, `ocml.bc` and `ockl.bc`.
Most functions are reused as-is, since they are target-independent.
Some math functions are implemented with __builtin to avoid AMDGPU intrinsics,
and the texture image functions are partially implemented in software.

`rocm-systems/projects/clr`  — the HIP runtime,
based on the ROCm CLR HIP runtime.
It adds a CPU device backend (clr/rocclr/device/cpu) behind the same device
interface as the GPU backend.
The backend implements the program, memory, kernel, and device operations
for the CPU.
The device image is a host shared library, and kernels run on a thread pool.

`rocm-libraries/projects/rocblas` — hipBLAS implementation for CPU,
based on the rocBLAS framework.
BLAS level 1 reuses pure HIP code, and BLAS level 3 calls OpenBLAS from
the kernel through asm symbols.
It is a feasibility implementation of hipBLAS on HIP on CPU,
covering only axpy and gemm.
For more information, read [hipcpu/hipblas/README.md](hipcpu/hipblas/README.md).

## License

MIT — see [LICENSE](LICENSE).

The names used in this repository and its submodules — ROCm, etc. — are
trademarks of AMD.
