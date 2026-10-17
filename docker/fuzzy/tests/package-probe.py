#!/usr/bin/env python3
"""Exercise compiled floating-point code in one package, with fixed inputs."""
import sys

package = sys.argv[1]
if package == "scipy":
    import numpy as np
    from scipy.special import expit
    values = expit(np.random.default_rng(17).uniform(-3, 3, 32))
elif package == "sklearn":
    import numpy as np
    from scipy.sparse import csr_matrix
    from sklearn.utils.sparsefuncs_fast import csr_mean_variance_axis0
    x = csr_matrix(np.random.default_rng(17).random((128, 8)))
    means, variances = csr_mean_variance_axis0(x)
    values = np.concatenate((means, variances))
else:
    import torch
    torch.set_num_threads(1)
    if package == "torch":
        x = torch.tensor([i / 37 for i in range(1, 33)], dtype=torch.float64, requires_grad=True)
        y = (x.sin() * x.exp()).sum()
        y.backward()
        values = [y.item(), *x.grad.tolist()]
    elif package == "torchaudio":
        from torchaudio.functional import lfilter
        x = torch.tensor([[i / 37 for i in range(1, 129)]], dtype=torch.float64)
        a = torch.tensor([1.0, -0.2, 0.3], dtype=torch.float64)
        b = torch.tensor([0.1, 0.2, 0.1], dtype=torch.float64)
        values = lfilter(x, a, b, clamp=False)[0, -16:].tolist()
    elif package == "torchvision":
        from torchvision.ops import roi_align
        x = torch.tensor([i / 37 for i in range(64)], dtype=torch.float64).reshape(1, 1, 8, 8)
        boxes = torch.tensor([[0, 0.13, 0.27, 6.17, 6.29]], dtype=torch.float64)
        values = roi_align(x, boxes, (4, 4), sampling_ratio=2).flatten().tolist()
    else:
        raise SystemExit(f"unknown package: {package}")
print(*(float(value).hex() for value in values))
