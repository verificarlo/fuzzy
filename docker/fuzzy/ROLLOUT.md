# Issue #53: v2.7.0 rollout

The release remains in progress. Implementation alone is not publication or
evidence that a CPU level passes its image checks.

## Required gates

- [ ] Build and test v3 with all nine registered packages in both flavors.
- [ ] Build and test v1, v2 and v4 with the same package set.
- [ ] Pass v1–v3 checks under Intel SDE with the target CPU profiles.
- [ ] Verify default and mixed selections, late runtime loading, seeded
  results, SR variation, RN agreement, runtime sharing, wheel level markers,
  RUNPATHs and ISA checks for the complete package set.
- [ ] Merge the reviewed implementation and verify the release workflow.
- [ ] Publish all level tags and ISA aliases; advance `latest` only after
  all four levels pass.
- [ ] Verify the published images and finish the documentation migration.

The hosted wheel index is optional. The image's flat wheel directories are
the required local distribution mechanism.

## Verified during implementation

- Verificarlo v2.7.0 includes the upstream PRISM dependency/configuration and
  double-word rounding changes. Its PRISM submodule is v0.0.12.
- The local v3 base reports Verificarlo 2.7.0; `libprism-static.so` lists
  `libprism-config.so` and `libhwy.so` as dependencies.
- Full images compiled on all four levels. Their native checks exposed a
  Meson `--as-needed` link dropping the Verificarlo initializer in SciPy and
  scikit-learn: RN and seed settings were ignored. Retaining that runtime
  fixes the C/C++/Fortran response-file regression with those linker flags.
  Full native checks then passed on v1, v2 and v4; further compiler audit
  found skipped instrumentation, so these are not release validation passes.
- LLVM 20 generated unsupported 64-lane vectors in ATen and non-power-of-two
  vectors in v4 LAPACK. Both flavors now use compatible loop/SLP settings;
  the compiler adapters fail on skipped instrumentation. The actual ATen
  normalization kernel compiles with strict PRISM instrumentation under the
  candidate settings. Complete builds with these settings remain required.
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
- All four offline Slurm builds are submitted. The controller has exercised
  clean-revision staging, submission and tracking; completion, archive
  verification and import remain to be checked.

## Current build configuration

PyTorch 2.5.1, torchaudio 2.5.1 and torchvision 0.20.1 are the matching
NumPy-2-compatible CPU stack. Optional JIT/quantized CPU backends are
disabled in both flavors; the precise configuration is documented in the
image guide. ATen and SLEEF compile flags and ATen dispatch are capped at
the selected level. These controls still require the full image tests on
each CPU level before publication.
