# Issue #53: v2.7.0 rollout

The implementation is merged and all four release images are published.
Native and target-CPU checks passed before publication.

## Required gates

- [x] Build v3 with all nine registered packages in both flavors and pass
  the complete native suite.
- [x] Build v1, v2 and v4 with the same package set and pass their complete
  native suites.
- [x] Pass v1–v3 checks under Intel SDE with the target CPU profiles.
- [x] Verify default and mixed selections, late runtime loading, seeded
  results, SR variation, RN agreement, runtime sharing, wheel level markers,
  RUNPATHs and ISA checks for the complete package set.
- [x] Merge the validated implementation and verify the release workflow.
- [x] Publish all level tags and ISA aliases; advance `latest` only after
  all four levels pass.
- [x] Verify the published images and finish the documentation migration.

The hosted wheel index is optional. The image's flat wheel directories are
the required local distribution mechanism.

## Current validation results

The image sources at `d1b6da7` passed the complete native suites on
Rorqual. They match the image inputs at `d42ffb1` and its merged master
commit `cd447d6`. Each image contains all nine registered packages in both
`ieee` and `prism` flavors.

| Level | Native PASS | Target-CPU SDE PASS | FAIL markers |
| --- | ---: | ---: | ---: |
| v1 | 106 | 106 | 0 |
| v2 | 106 | 106 | 0 |
| v3 | 106 | 106 | 0 |
| v4 | 106 (AVX-512 hardware) | Not required | 0 |

These results include the compiler regressions, package numerical checks,
mixed selections, shared runtime, wheel metadata, RUNPATH and ISA audits,
and CLI checks. The SciPy, scikit-learn, PyTorch, torchaudio and torchvision
probes import the first PRISM extension into plain CPython with IEEE
dependencies. Their RN, reduced-precision and seed checks exercise late
runtime loading. A separate check loads all six instrumented Python
packages together and rejects private PRISM copies.
The same complete suite passed under the v1–v3 SDE CPU profiles. All four
Slurm jobs completed with exit 0, and their exported archives were
checksum-verified and imported with matching canonical/ISA image IDs,
release labels and runtime settings.

The [hosted PR validation run](https://github.com/verificarlo/fuzzy/actions/runs/39129594118)
also passed the full native and target-CPU suites for v1–v3, with 106 PASS
markers and zero FAIL markers in each suite. Artifact checksum checks,
image loading, label verification and all protected checks passed.
[PR #56](https://github.com/verificarlo/fuzzy/pull/56) merged as `cd447d6`.
The [master publication run](https://github.com/verificarlo/fuzzy/actions/runs/39421857770)
passed the native and target-CPU gates, published all canonical and ISA
tags, and advanced `latest` to v1. All five protected checks passed.

## Release verification

The master run passed all four native build jobs. Its v1–v3 target-CPU
suites each passed all 106 checks with zero FAIL markers and published their
canonical and ISA tags. After those gates passed, the `latest` push
completed at 2026-10-20 20:26:25 UTC (2026-10-20 in America/Toronto).

The public v1–v3 manifests match both digest summaries in their
successful publisher logs. `latest` has the same manifest as v1, matching
its publisher log. The v4 canonical and AVX-512 tags share the
configuration of the image tested on AVX-512 hardware:
`sha256:bebec2025470de3f481b09c3b388a931666a955d2cf0e8c6f599ee65e129a71e`.
Each verified image reports Linux/amd64, its expected CPU level and
Verificarlo v2.7.0, and the default PRISM SR and libm preload settings.

| Level | Canonical and ISA-alias manifest |
| --- | --- |
| v1 / sse2 | `sha256:b0dafe9ab075c28268ea788dcf4a7c76076eec1bd2aac9b04cd099c96bee6fa5` |
| v2 / sse4 | `sha256:70ccb03e4d0a657aa67154a026248d3c1aa15ad446fb169e113572d7ca63c317` |
| v3 / avx2 | `sha256:da709396a54527a2c369b6e3831a95f53d4946347c9c5fa83f6049042b199c43` |
| v4 / avx512 | `sha256:6224a3add47e70b77981c430b2dfa320f27d85447ca9ad35bb86f165388b0bba` |

The v4 publisher initially failed because Podman requires an explicit
registry for login. Its targeted retry used `docker.io`, succeeded and
reused the completed native build. The workflow fix selects `docker.io`
explicitly for all Docker Hub login commands. The native v1–v3 build
artifacts were preserved for their complete target-CPU checks.

## Verified during implementation

- Verificarlo v2.7.0 includes the upstream PRISM dependency/configuration and
  double-word rounding changes. Its PRISM submodule is v0.0.12.
- The local v3 base reports Verificarlo 2.7.0; `libprism-static.so` lists
  `libprism-config.so` and `libhwy.so` as dependencies.
- Full images compiled on all four levels. Their native checks exposed a
  Meson `--as-needed` link dropping the Verificarlo initializer in SciPy and
  scikit-learn: RN and seed settings were ignored. Retaining that runtime
  fixes the C/C++/Fortran response-file regression with those linker flags.
  The complete native suites pass on all four levels with the current
  compiler adapter. The full v1–v3 target-CPU suites also pass.
- LLVM 20 generated unsupported 64-lane vectors in ATen and non-power-of-two
  vectors in LAPACK and NumPy. The adapter splits unsupported FP32/FP64
  arithmetic and FMA operations into supported vector chunks and scalar
  tails before instrumentation. Normal vectorization remains enabled; the
  adapters reject skipped instrumentation. The actual ATen normalization
  kernel compiles with no residual native FP arithmetic.
- Native v4 regression tests exposed a calling-convention mismatch for
  injected 512-bit calls. Setting the caller's LLVM minimum vector width
  preserves PRISM's ZMM ABI. Native FP32/FP64 arithmetic, FMA, RN/SR and
  C/C++/Fortran wrapper checks pass on AVX-512 hardware. Original SCAL
  sources also pass through lengths of 129 with strict instrumentation,
  no residual native arithmetic, and correct strides and padding.
- Pillow's prebuilt JPEG/AVIF codec kernels triggered the static register
  scan. Encoding and decoding JPEG, AVIF, PNG, WebP, TIFF and JPEG2000 passed
  under the v1, v2 and v3 CPU profiles. These uninstrumented codecs use CPU
  dispatch; the mandatory complete-image SDE gate now exercises them too.
- The v1 SDE CPUID profile accepts a baseline executable and rejects SSE3.
- SDE 9.58 follows Python subprocesses on the workstation and Rorqual;
  the v1 profile rejects SSE3 in a followed child. C and C++ response-file
  checks pass under v1 and v2 emulation. SDE 10.13.1 fails the Python
  `close_fds=True` process-launch probe, so compatibility checks pin 9.58.
- Workflow validation with actionlint and shell/Python syntax checks pass.
- The offline adapters pass a local test with networking disabled: Python
  environment seeding, local wheel installation, source archive retrieval,
  git checkout recovery and apt dependency verification.
- All four Verificarlo bases and their prepared apt/uv OCI archives are
  built and staged. The v4 static PRISM library contains ZMM instructions.
- Rorqual has the required AVX-512 CPU features. A Slurm preflight can run
  a staged Ubuntu OCI image with rootless Podman using
  `overlay.ignore_chown_errors=true`. Compute nodes cannot fetch GitHub;
  the hashed sources and wheel dependencies are staged for offline builds.
- The controller has exercised immutable clean-revision staging, Slurm
  submission and tracking, and restoration of completed package stages.
  All four validated OCI archives have been checksum-verified and imported,
  with matching canonical/ISA image IDs and the expected release labels.
  The master publication workflow completed successfully.

## Current build configuration

PyTorch 2.5.1, torchaudio 2.5.1 and torchvision 0.20.1 are the matching
NumPy-2-compatible CPU stack. Optional JIT/quantized CPU backends are
disabled in both flavors; the precise configuration is documented in the
image guide. ATen and SLEEF compile flags and ATen dispatch are capped at
the selected level. Complete native suites have passed at each level,
and v1–v3 have also passed the complete target-CPU suite. The master
workflow has published the validated release images.
