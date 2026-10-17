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
- C and C++ response-file regression checks pass, including actual PRISM
  linkage, deterministic RN and stochastic SR. The full image rerun is pending.
- The v1 SDE CPUID profile accepts a baseline executable and rejects SSE3.
- Workflow validation with actionlint and shell/Python syntax checks pass.
- The offline adapters pass a local test with networking disabled: Python
  environment seeding, local wheel installation, source archive retrieval,
  git checkout recovery and apt dependency verification.
- The v4 Verificarlo base is built; its static PRISM library contains ZMM
  instructions. The prepared apt/uv base is ready for the Rorqual build.
- Rorqual has the required AVX-512 CPU features. A Slurm preflight can run
  a staged Ubuntu OCI image with rootless Podman using
  `overlay.ignore_chown_errors=true`. Compute nodes cannot fetch GitHub;
  build inputs are being staged for an offline build.

## Current build configuration

PyTorch 2.5.1, torchaudio 2.5.1 and torchvision 0.20.1 are the matching
NumPy-2-compatible CPU stack. Optional JIT/quantized CPU backends are
disabled in both flavors; the precise configuration is documented in the
image guide. ATen and SLEEF compile flags and ATen dispatch are capped at
the selected level. These controls still require the full image tests on
each CPU level before publication.
