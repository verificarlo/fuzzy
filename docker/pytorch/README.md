# Fuzzy PyTorch

`verificarlo/fuzzy:v2.6.0-pytorch2.2.1-<isa>` on Docker Hub: PyTorch 2.2.1,
torchaudio 2.2.1, torchvision 0.17.2 and reference LAPACK compiled with
Verificarlo v2.6.0 and its PRISM v0.0.8 stochastic-rounding pass.

| Tag suffix | `-march`    | Runs on                                              |
| ---------- | ----------- | ---------------------------------------------------- |
| `sse2`     | `x86-64`    | any x86-64 CPU                                       |
| `sse4`     | `x86-64-v2` | SSE4.2 CPUs                                          |
| `avx2`     | `x86-64-v3` | AVX2 CPUs (Intel Haswell, AMD Zen and later)         |
| `avx512`   | `x86-64-v4` | AVX-512 CPUs (Intel Skylake-SP, AMD Zen 4 and later) |

Use the widest variant your nodes support; a wider one crashes with SIGILL on
a CPU that lacks its instructions. **Pick one tag for a whole study and record
it with your results.** Results agree across variants for RN at reduced
precision, but can differ in the last digits between `sse2`/`sse4` and the
variants with hardware FMA, since without it PyTorch and BLAS compute
`a*b + c` as a separate multiply and add.

## Building

PRISM's static kernels are compiled for one instruction set inside the
Verificarlo image, so each variant rebuilds Verificarlo for its `-march`
(`Dockerfile.verificarlo`) and then compiles PyTorch with the same flag
(`Dockerfile.pytorch`). On a machine whose CPU supports the variant, from the
repository root:

```bash
docker/pytorch/build.sh avx2 podman     # or docker; ISA: sse2, sse4, avx2, avx512
```

The build runs `test_fuzzy_pytorch.py` and `test_fuzzy_pytorch_grad.py`, then
fails unless `libprism-static.so` uses the variant's vector registers (xmm only
for `sse2`/`sse4`, ymm for `avx2`, zmm for `avx512`).

The published images were built by
[fuzzy-llm](https://github.com/big-data-lab-team/fuzzy-llm/tree/main/containers)
at d7a635f. This recipe differs in one way that changes the binaries:
torchaudio and torchvision are also compiled with `-march=<level>`, where the
published images compiled them for baseline x86-64.
