#!/usr/bin/env python3
"""Reject PyTorch compiler flags that exceed the selected static PRISM ABI."""
import json
from pathlib import Path
import re
import shlex
import sys

march, path = sys.argv[1:]
level = {"x86-64": 1, "x86-64-v2": 2, "x86-64-v3": 3, "x86-64-v4": 4}[march]
bad = []
for entry in json.loads(Path(path).read_text()):
    args = entry.get("arguments") or shlex.split(entry["command"])
    for arg in args:
        forbidden = arg.startswith("-march=") and arg != f"-march={march}"
        forbidden |= level < 4 and arg.startswith("-mavx512")
        forbidden |= arg.startswith("-mavx512") and arg not in {
            "-mavx512f", "-mavx512dq", "-mavx512cd", "-mavx512bw", "-mavx512vl"}
        forbidden |= arg in {"-mfma4", "-mxop", "-msse4a", "-maes", "-mpclmul", "-mavxvnni"}
        forbidden |= level < 3 and bool(re.match(r"-m(avx|fma|f16c)", arg))
        forbidden |= level == 1 and bool(re.match(r"-m(sse3|ssse3|sse4|popcnt)", arg))
        if forbidden:
            bad.append(f"{entry['file']}: {arg}")
if bad:
    raise SystemExit("compiler options exceed the image ISA:\n" + "\n".join(bad[:30]))
print(f"compiler options match {march}")
