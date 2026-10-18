# Fuzzy, one image per x86-64 level

`verificarlo/fuzzy:v2.7.0-x86-64-v<N>` contains every package twice: built
with Verificarlo's PRISM backend (`prism`, stochastic rounding) and built
without instrumentation (`ieee`), with the same compiler, flags and `-march`.
You choose a build per package at run time, without rebuilding anything.
Instrumentation does not change a library's ABI, so both builds have the same
sonames and Python ABI, and any mix of them works: instrumented NumPy with a
plain LAPACK instruments only NumPy.

The recipes cover all four levels, `x86-64-v1` through `x86-64-v4`
([#53](https://github.com/verificarlo/fuzzy/issues/53)). The v4 build requires
an AVX-512 machine.

| Package  | Version | Kind        |
| -------- | ------- | ----------- |
| `lapack` | 3.12.1  | native      |
| `python` | 3.12.13 | interpreter |
| `numpy`  | 2.4.6   | python      |
| `libm`   | quad    | native      |
| `scipy`  | 1.18.0  | python      |
| `sklearn` | 1.9.0  | python      |
| `torch` | 2.5.1 | python |
| `torchaudio` | 2.5.1 | python |
| `torchvision` | 0.20.1 | python |

By default every package uses its `prism` build and
`VFC_BACKENDS="libinterflop_prism.so --mode=sr"`.

`libm=prism` replaces the C library's `sin`, `tan`, `exp`, `exp2`, `log`,
`pow`, `atan2`, `tanh`, `erf`, `lgamma`... (in `float` and `double`; the list is in
`recipes/libm/fuzzy-libm.c`) for every program in the image, instrumented or
not. Each result is computed in binary128 with libquadmath, then rounded by
PRISM with its current mode and precision: rounded to nearest under
`--mode=rn`, stochastically rounded under `--mode=sr`. The image preloads
`libfuzzy-libm.so` (`LD_PRELOAD`), which the loader finds through
`LD_LIBRARY_PATH`; `libm=ieee` selects an empty one, and the functions come
from glibc. Other functions (`exp10`, `fma`, `remainder`...) always come from
glibc.

## Choosing builds

```bash
fuzzy list                                  # packages, builds, current selection
fuzzy use lapack=ieee numpy=prism           # switch, persistently
fuzzy run lapack=ieee -- python3 script.py  # one command, nothing changed
eval "$(fuzzy env python=ieee)"             # the same, for the current shell
```

- **`lapack`, `python`, `libm`**: `fuzzy use` moves the symlinks in
  `/opt/fuzzy/active`, which is on `LD_LIBRARY_PATH`. `fuzzy run` and
  `fuzzy env` put the other build first on `LD_LIBRARY_PATH` (and
  `PYTHONPATH` for CPython's extension modules) instead. They work on
  read-only images such as Apptainer SIF files.
- **Python packages**: `fuzzy use` installs the chosen `+ieee` or `+prism` wheel with
  `uv`, from the wheels in `/opt/fuzzy/wheels/{ieee,prism}`. It installs into
  the environment given by `--python ENV`, otherwise `$VIRTUAL_ENV`, otherwise
  `/opt/fuzzy/venv` (the image's default environment, first on `PATH`). On a
  read-only image, create an environment on writable storage first:

  ```bash
  uv venv ~/env --python /opt/fuzzy/python/3.12/bin/python3
  fuzzy use --python ~/env numpy=prism
  ```

PRISM's run-time options apply to every `prism` build in the process:

```bash
VFC_BACKENDS="libinterflop_prism.so --mode=rn" python3 script.py              # round to nearest
VFC_BACKENDS="libinterflop_prism.so --precision-binary64=40" python3 script.py # reduced precision
VFC_BACKENDS="libinterflop_prism.so --seed=42" python3 script.py              # fixed seed
```

PRISM's `rn` does not break ties like IEEE round-to-nearest, so `--mode=rn`
can differ from `ieee` in the last bits.

Stochastic rounding does not change exact operations, so compensated
algorithms keep their accuracy under it. In particular, CPython 3.12's `sum()`
of floats uses compensated summation, and `sum([0.001] * 1000)` gives the same
result in every run. An explicit loop varies:

```bash
python3 -c "
s = 0.0
for _ in range(1000): s += 0.001
print(s)"
```

## Your own recipe

```dockerfile
FROM verificarlo/fuzzy:v2.7.0-x86-64-v3
RUN fuzzy use numpy=prism lapack=ieee && uv pip install pandas
```

In a `uv` project, take the instrumented wheels from the image's wheel
directory:

```toml
[[tool.uv.index]]
name = "fuzzy-prism"
url = "/opt/fuzzy/wheels/prism"
format = "flat"
explicit = true

[tool.uv.sources]
numpy = { index = "fuzzy-prism" }
```

Every `prism` wheel requires `fuzzy-prism-runtime==<prism>+x86.64.v<N>`, which
only that level's image provides, so a wheel built for another level fails to
install instead of running with the wrong vector width. For your own C, C++
or Fortran code, compile with `verificarlo-c` and the same flags as the
image's `prism` builds:

```text
--prism-backend=sr --prism-backend-dispatch=static --prism-backend-strict-abi
-march=x86-64-v3 --inst-fma
```

Before PRISM instrumentation, the compiler adapter splits unsupported
floating-point vector operations into supported power-of-two chunks and
scalar tails. It preserves lane order and fast-math flags; other operations
and normal compiler vectorization remain unchanged. Chunk widths follow
the image's CPU level. On v4, the adapter also sets LLVM's minimum vector
width for injected 512-bit calls, keeping their ZMM calling convention
consistent with PRISM. The adapters reject warnings about skipped PRISM
operations. ATen's explicit SIMD kernels and SLEEF target the image's CPU
level.

## Layout

```
/usr/local/lib/                              Verificarlo and PRISM runtime, built for the level
/opt/fuzzy/lib/<pkg>/<version>/{ieee,prism}/ native libraries; for CPython: libpython and lib-dynload
/opt/fuzzy/python/3.12/                      CPython prefix, shared by both builds
/opt/fuzzy/wheels/{ieee,prism}/              Python packages
/opt/fuzzy/registry/<pkg>.env                package manifests, read by fuzzy
/opt/fuzzy/active/                           the selected builds (symlinks)
/opt/fuzzy/venv/                             default environment
```

## Building

On a machine whose CPU supports the level, from the repository root:

```bash
docker/fuzzy/build.sh v3 podman     # or docker
```

To build against an unreleased Verificarlo, pass a checkout (with submodules)
and the versions it contains:

```bash
VERIFICARLO_SRC=~/verificarlo FUZZY_VERIFICARLO_VERSION=dev FUZZY_PRISM_VERSION=0.0.12 docker/fuzzy/build.sh v3
```

The script builds the level's Verificarlo image (using the release's own Dockerfile) unless it
exists already, then `docker/fuzzy/Dockerfile`. Each package has one
recipe, `recipes/<pkg>/build.sh <ieee|prism>`; `recipes/common.sh` holds the
flags of the two builds. The `test` stage runs `tests/run.sh`, which checks
that each `prism` build varies under `--mode=sr` and that each `ieee` build
does not, and that the PRISM libraries load on their own (they need `libhwy`
and the shared `libprism-config`). It also checks that `prism --mode=rn` stays
within 16 ULPs of `ieee` for the numerical probes and that mixed selections
perturb only what they should. Finally, it
checks that the built packages use no vector registers wider than the level,
that no RUNPATH points into a build directory, and that the `fuzzy` tool works.
Pillow's uninstrumented, prebuilt JPEG and AVIF codecs contain kernels for
several CPUs and select them through CPUID. Those two codec libraries are
exempt from the static register scan; JPEG, AVIF, PNG, WebP, TIFF and JPEG2000
encoding and decoding must pass on each target CPU under SDE instead.

## PyTorch CPU backends

PyTorch 2.5.1 and its matching torchaudio/torchvision releases support the
NumPy 2 C ABI used here. Both flavors use the same CPU configuration. ATen's
compile checks and dispatch are capped at the image level, including when
`ATEN_CPU_CAPABILITY` is overridden. v1/v2 use DEFAULT kernels compiled for
the image's `-march`; v3 uses AVX2 and v4 uses AVX-512.

CUDA, ROCm, oneDNN, FBGEMM, XNNPACK, QNNPACK and NNPACK are disabled in both
flavors. These optional backends generate uninstrumented code or compile
kernels wider than the image's static PRISM ABI. In particular, this FBGEMM
release requires compiling AVX-512 even on an AVX2 target. Floating-point CPU
operations use ATen and the switchable LAPACK/BLAS. Quantized backend support
is not provided by these recipes. torchaudio includes its native filters and
Kaldi operators; FFmpeg/SoX and torchvision video codecs are disabled.

## CPU compatibility and publication

The workflow builds and tests v1–v3 on hosted runners and v4 on
`[self-hosted, Linux, X64, avx512]`. External fork PRs use hosted runners;
their own push workflows may test v4 on a trusted runner in the fork.

For a local compatibility check:

```bash
docker/fuzzy/tests/install-sde.sh /tmp/intel-sde
docker/fuzzy/tests/run-sde.sh v3 verificarlo/fuzzy:v2.7.0-x86-64-v3 /tmp/intel-sde podman
```

SDE uses an SSE2-only CPUID definition for v1, Nehalem for v2 and Haswell for
v3, follows subprocesses and fails on instructions outside the target ISA.
Every image must pass its native checks and (for v1–v3) SDE checks before CI
publishes its level and ISA tags. `latest` advances to v1 only after all four
levels pass. Existing per-stack tags remain legacy and are no longer rebuilt
by the release workflow. The flat wheel directories in each image remain the
local index; a hosted index is not required for this rollout.
