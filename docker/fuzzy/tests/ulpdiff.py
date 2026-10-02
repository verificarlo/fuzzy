#!/usr/bin/env python3
"""ulpdiff.py A B MAX_ULP: compare two outputs token by token.

Tokens that parse as hexadecimal floats (float.hex() or printf %a) are
compared in ULPs of binary64, all other tokens must be equal. Prints the
largest distance and exits with 1 if it exceeds MAX_ULP or the outputs do not
line up.
"""

import math
import struct
import sys


def ordered(x):
    """Map a double to an integer so that adjacent doubles differ by 1."""
    (bits,) = struct.unpack("<q", struct.pack("<d", x))
    return bits if bits >= 0 else -(bits & 0x7FFFFFFFFFFFFFFF)


def as_float(token):
    try:
        return float.fromhex(token)
    except ValueError:
        return None


def main():
    path_a, path_b, max_ulp = sys.argv[1], sys.argv[2], int(sys.argv[3])
    a = open(path_a).read().split()
    b = open(path_b).read().split()
    if len(a) != len(b):
        sys.exit(f"{path_a} and {path_b} have {len(a)} and {len(b)} tokens")
    worst = 0
    for x, y in zip(a, b):
        fx, fy = as_float(x), as_float(y)
        if fx is None or fy is None:
            if x != y:
                sys.exit(f"{x!r} != {y!r}")
            continue
        if math.isnan(fx) or math.isnan(fy):
            if not (math.isnan(fx) and math.isnan(fy)):
                sys.exit(f"{x} != {y}")
            continue
        worst = max(worst, abs(ordered(fx) - ordered(fy)))
    print(f"max {worst} ulp")
    sys.exit(1 if worst > max_ulp else 0)


if __name__ == "__main__":
    main()
