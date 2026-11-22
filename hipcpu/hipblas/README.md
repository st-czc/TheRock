# hipBLAS on CPU

Builds `librocblas.so` and `libhipblas.so` for the HIP-on-CPU backend, and
the axpy/gemm samples that use them.

## Build

Requires the toolchain at `install/` and the `rocm-libraries` submodules.

```sh
./hipcpu/hipblas/build.sh
```

The script builds `hipblas-common`, `rocblas`, and `hipblas` from
`rocm-libraries/projects/`, installing them to `install/lib`. `rocblas` is
built host-only: the BLAS math functions are stubs that return
`rocblas_status_not_implemented`, while the framework keeps its real
definitions.

## Samples

`samples/` has `hip_axpy` and `hip_gemm`, compiled with
`clang++ -x hip --offload-arch=spvcpu` and linked against `libhipblas` and
`librocblas`.

```sh
./hipcpu/hipblas/samples/build.sh
LD_LIBRARY_PATH=install/lib hipcpu/hipblas/samples/out/hip_axpy
LD_LIBRARY_PATH=install/lib hipcpu/hipblas/samples/out/hip_gemm
```
