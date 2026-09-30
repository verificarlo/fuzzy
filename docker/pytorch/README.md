# Images

Recipe of the images the experiments run in,
`verificarlo/fuzzy:v2.6.0-pytorch2.2.1-<isa>` on Docker Hub: PyTorch 2.2.1
compiled with Verificarlo v2.6.0 and its PRISM v0.0.8 stochastic-rounding pass.

| Tag suffix | `-march`    | Runs on                                          |
| ---------- | ----------- | ------------------------------------------------ |
| `sse2`     | `x86-64`    | any x86-64 CPU                                   |
| `sse4`     | `x86-64-v2` | SSE4.2 CPUs                                      |
| `avx2`     | `x86-64-v3` | AVX2 CPUs (Intel Haswell, AMD Zen and later)     |
| `avx512`   | `x86-64-v4` | AVX-512 CPUs (Intel Skylake-SP, AMD Zen 4 and later) |

PRISM's static kernels are compiled for one instruction set inside the
Verificarlo image, so each variant rebuilds Verificarlo for its `-march`
(`Dockerfile.verificarlo`, Verificarlo v2.6.0's own Dockerfile with two marked
changes) and then compiles PyTorch with the same flag (`Dockerfile.pytorch`).
To rebuild one, on a machine whose CPU supports the variant:

```bash
containers/build.sh avx2 podman     # or docker; ISA: sse2, sse4, avx2, avx512
```

This recipe reproduces the published `avx2` image exactly: rebuilt from the
same Verificarlo checkout, it has the same image ID.

Results agree across variants for RN at reduced precision, but can differ in
the last digits between `sse2`/`sse4` and the variants with hardware FMA,
since without it PyTorch and BLAS compute `a*b + c` as a separate multiply and
add.
