#!/usr/bin/env python3
"""All instrumented extensions must share the image's one PRISM runtime."""
from pathlib import Path
import re

import numpy
import scipy.special
import sklearn.utils.sparsefuncs_fast
import torch
import torchaudio
import torchvision

# Exercise native ops so dlopen of lazy extension modules has happened.
torch.ones(8).sum()
torchaudio.functional.lfilter(torch.ones(1, 16), torch.tensor([1., .2]), torch.tensor([.3, .1]))
torchvision.ops.roi_align(torch.ones(1, 1, 8, 8), torch.tensor([[0., 0., 0., 6., 6.]]), (2, 2))
paths = {Path(line.split()[-1]).resolve() for line in Path('/proc/self/maps').read_text().splitlines()
         if re.search(r'/lib(?:prism|interflop_prism)[^/]*\.so', line)}
assert paths, 'no PRISM runtime was loaded'
for path in paths:
    assert path.parent == Path('/usr/local/lib'), f'private PRISM runtime loaded: {path}'
for name in ('libprism-static', 'libprism-config', 'libinterflop_prism'):
    matching = [p for p in paths if p.name.startswith(name + '.so')]
    assert len(matching) == 1, (name, matching)
print('[PASS] every prism package shares one runtime')
