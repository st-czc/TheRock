# HIP on CPU

A TheRock-based build of HIP that runs on CPUs via the SYCL Native CPU passes.
Paths are relative to the super-project root.

## Global instructions

- Add comments only where strictly necessary: non-trivial code, or
  function/class signatures whose arguments aren't self-explanatory.
- Do not remove existing comments unless they relate directly to what you are
  changing.
- Do not run `rg`/`grep` across the whole repo; narrow the directories first.

## Layout

- `compiler/llvm-project` — LLVM/Clang base (upstream main commit).
- `compiler/amd-llvm` — pruned ROCm/llvm-project (comgr, device-libs, hipcc); builds against `compiler/llvm-project`.
- `compiler/hipcpu-passes` — `sycl-native-cpu` pass plugin; builds against `compiler/llvm-project`.
- `compiler/hipcpu-artifacts` — prebuilt `libsycl-nativecpu_utils.bc`; `compiler/hipcpu-artifacts/intel-llvm` is the reference intel/llvm checkout.
- `rocm-systems/projects/clr` — HIP runtime; CPU backend in `clr/rocclr/device/cpu`.
- `rocm-libraries/projects/rocblas` — rocBLAS submodule; built host-only by `hipcpu/hipblas/build.sh`.
- `hipcpu/hip-tests` — HIP unit-test harness.
- `hipcpu/hipblas` — hipBLAS-on-CPU build scripts and samples; `samples/` has axpy and gemm.

## Sub-project docs

Read the matching doc before working under these paths:

- `compiler/hipcpu-passes` → `hipcpu/docs/hipcpu-passes.md`
- `rocm-systems/projects/clr` → `hipcpu/docs/clr.md`

## Compilation flow

1. Clang compiles device code for the `spvcpu` target to LLVM bitcode.
2. `llvm-link` merges that bitcode with `libsycl-nativecpu_utils.bc`.
3. `opt` runs the `sycl-native-cpu` pipeline from `hipcpu-passes`, lowering the bitcode to host code.
4. Clang compiles the host code to a shared library (the device image).

## Build

Full build:

```sh
./hipcpu/update_submodules.sh
./hipcpu/build.sh
```

Incremental rebuild:

```sh
cmake --build build -- install
```

Compiler exception: after editing `compiler/llvm-project`,
`compiler/hipcpu-passes`, or `compiler/amd-llvm`, rebuild `compiler/amd-llvm`
first:

```sh
cmake --build build/compiler/amd-llvm/build -- install
cmake --build build -- install
```

## Test

```sh
./hipcpu/hip-tests/run.sh --help
```

Read `hipcpu/hip-tests/readme.md` before using the harness.

## Bounds

- Use only the build entry points above.
- Do not run `build_tools/fetch_sources.py`; it resets all submodules and
  reapplies patches.
- The remote configuration (URLs, branches, pins) is user-maintained. Do not
  change it.
