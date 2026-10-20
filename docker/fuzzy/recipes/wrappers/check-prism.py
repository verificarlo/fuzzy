#!/usr/bin/python3
"""Reject Verificarlo compilations that leave unsupported operations native."""
import re
import subprocess
import sys

# Strict ABI mode rejects missing PRISM functions, but Verificarlo v2.7.0
# only warns about other unsupported vector shapes. Preserve the original
# compiler streams and reject those warnings too.
unsupported = re.compile(
    rb'^(?:Warning: Function not found: prism::'
    rb'|(?:Unsuported|Unsupported) vector size:'
    rb'|Unsupported operand type\s*$'
    rb'|Warning: scalable vector operations .*left uninstrumented)'
)
process = subprocess.Popen(sys.argv[1:], stderr=subprocess.PIPE)
skipped = False
for line in process.stderr:
    sys.stderr.buffer.write(line)
    sys.stderr.buffer.flush()
    skipped |= unsupported.search(line) is not None
status = process.wait()
if skipped:
    print('fuzzy: PRISM skipped operations; refusing this build', file=sys.stderr)
    status = status or 1
raise SystemExit(status if status >= 0 else 128 - status)
