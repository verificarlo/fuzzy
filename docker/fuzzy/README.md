# Fuzzy, one image per x86-64 level

`verificarlo/fuzzy:v2.6.0-x86-64-v<N>` contains every package twice: built
with Verificarlo's PRISM backend (`prism`, stochastic rounding) and built
without instrumentation (`ieee`), with the same compiler, flags and `-march`.
You choose a build per package at run time, without rebuilding anything.
Instrumentation does not change a library's ABI, so both builds have the same
sonames and Python ABI, and any mix of them works: instrumented NumPy with a
plain LAPACK instruments only NumPy.

This is a prototype ([#53](https://github.com/verificarlo/fuzzy/issues/53)):
only the `x86-64-v3` (`avx2`) image, with LAPACK, CPython and NumPy.

| Package  | Version | Kind        |
| -------- | ------- | ----------- |
| `lapack` | 3.12.1  | native      |
| `python` | 3.12.13 | interpreter |
| `numpy`  | 2.4.6   | python      |

By default every package uses its `prism` build and
`VFC_BACKENDS="libinterflop_prism.so --mode=sr"`. The C library's math
functions (`libm`) are not instrumented: PRISM cannot perturb them yet
([verificarlo/prism#21](https://github.com/verificarlo/prism/issues/21)).

## Choosing builds

```bash
fuzzy list                                  # packages, builds, current selection
fuzzy use lapack=ieee numpy=prism           # switch, persistently
fuzzy run lapack=ieee -- python3 script.py  # one command, nothing changed
eval "$(fuzzy env python=ieee)"             # the same, for the current shell
```

- **`lapack`, `python`**: `fuzzy use` moves the symlinks in
  `/opt/fuzzy/active`, which is on `LD_LIBRARY_PATH`. `fuzzy run` and
  `fuzzy env` put the other build first on `LD_LIBRARY_PATH` (and
  `PYTHONPATH` for CPython's extension modules) instead. They work on
  read-only images such as Apptainer SIF files.
- **`numpy`**: `fuzzy use` installs `numpy==2.4.6+ieee` or `+prism` with
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
FROM verificarlo/fuzzy:v2.6.0-x86-64-v3
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
`--prism-backend=sr --prism-backend-dispatch=static -march=x86-64-v3 --inst-fma`.

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

The script builds the level's Verificarlo image (`docker/pytorch/Dockerfile.verificarlo`) unless it
exists already, then `docker/fuzzy/Dockerfile`. Each package has one
recipe, `recipes/<pkg>/build.sh <ieee|prism>`; `recipes/common.sh` holds the
flags of the two builds. The `test` stage runs `tests/run.sh`, which checks
that each `prism` build varies under `--mode=sr` and that each `ieee` build
does not. It also checks that `prism --mode=rn` stays within a few ULPs of
`ieee` and that mixed selections perturb only what they should. Finally, it
checks that no binary uses vector registers wider than the level, that no
RUNPATH points into a build directory, and that the `fuzzy` tool works.
