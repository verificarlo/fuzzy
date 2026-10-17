#!/usr/bin/env python3
"""Cap ATen's dispatch at the image ISA, even if a user overrides its env var."""
from pathlib import Path
import sys

march, root = sys.argv[1:]
capability = {"x86-64": "DEFAULT", "x86-64-v2": "DEFAULT",
              "x86-64-v3": "AVX2", "x86-64-v4": "AVX512"}[march]
path = Path(root) / "aten/src/ATen/native/DispatchStub.cpp"
source = path.read_text()
needle = "static CPUCapability compute_cpu_capability() {"
if source.count(needle) != 1:
    raise SystemExit("ATen dispatch changed: review the image ISA cap")
source = source.replace(needle, needle + f"\n  return CPUCapability::{capability}; // Fuzzy: image ISA, never host CPUID")
path.write_text(source)

# DEFAULT uses portable vector helpers. LLVM can re-vectorize their loops
# into 64-lane operations that PRISM does not export. Limit that extra
# vectorization in both flavors; retain normal optimization for all other
# sources and the explicit AVX2/AVX-512 kernels.
path = Path(root) / "cmake/Codegen.cmake"
source = path.read_text()
needle = 'list(APPEND CPU_CAPABILITY_FLAGS "${OPT_FLAG}")'
if source.count(needle) != 1:
    raise SystemExit("ATen DEFAULT compiler flags changed: review the PRISM vector cap")
path.write_text(source.replace(
    needle, 'list(APPEND CPU_CAPABILITY_FLAGS "${OPT_FLAG} -mllvm -force-vector-width=4")'))

# SLEEF enables its scalar FMA implementation unconditionally and gives it
# AVX2 compiler flags. The SIMD DISABLE switches do not cover this target.
if march in ("x86-64", "x86-64-v2"):
    path = Path(root) / "third_party/sleef/Configure.cmake"
    source = path.read_text()
    needle = "set(COMPILER_SUPPORTS_PURECFMA_SCALAR 1)"
    if source.count(needle) != 1:
        raise SystemExit("SLEEF scalar FMA configuration changed: review its ISA cap")
    path.write_text(source.replace(needle, "set(COMPILER_SUPPORTS_PURECFMA_SCALAR 0)"))
