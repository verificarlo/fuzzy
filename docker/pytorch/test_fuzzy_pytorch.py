import torch
import pickle
import numpy as np
import os

rounding_mode = os.environ.get("PRISM_ROUNDING_MODE","").lower()
if rounding_mode == "":
    print("Rounding mode not set. Defaulting to 'stochastic-rounding'")
else:
    print("Rounding mode set to: ", rounding_mode)

N_SAMPLES = 30

torch.manual_seed(0)
a = torch.rand(5, 5)
b = torch.rand(5, 5)

matmul = []
for _ in range(N_SAMPLES):
    matmul.append(a @ b)

m = torch.nn.Linear(20, 30)
a = torch.randn(128, 20)

matmul_layer = []
for _ in range(N_SAMPLES):
    matmul_layer.append(m(a))

filters = torch.randn(8, 4, 3, 3)
inputs = torch.randn(1, 4, 5, 5)

conv = []
for _ in range(N_SAMPLES):
    conv.append(torch.nn.functional.conv2d(inputs, filters, padding=1))

m = torch.nn.Conv2d(16, 33, 3, stride=2)
a = torch.randn(20, 16, 50, 100)

conv_layer = []
for _ in range(N_SAMPLES):
    conv_layer.append(m(a))

with open("fuzzy-pytorch_matmul_results.pickle", "wb") as file:
    pickle.dump(torch.stack(matmul), file)

with open("fuzzy-pytorch_matmul_layer_results.pickle", "wb") as file:
    pickle.dump(torch.stack(matmul_layer), file)

with open("fuzzy-pytorch_conv_results.pickle", "wb") as file:
    pickle.dump(torch.stack(conv), file)

with open("fuzzy-pytorch_conv_layer_results.pickle", "wb") as file:
    pickle.dump(torch.stack(conv_layer), file)

torch.manual_seed(0)
a = torch.rand(5, 5)
b = torch.rand(5, 5)

a = a.detach().numpy()
b = b.detach().numpy()

correct_res = a @ b

# Convert to numpy to avoid instrumenting the operations
mca_res = torch.stack(matmul).detach().numpy()
matmul_layer = torch.stack(matmul_layer).detach().numpy()
conv = torch.stack(conv).detach().numpy()
conv_layer = torch.stack(conv_layer).detach().numpy()

mean_res = mca_res.mean(axis=0)
relative_errors = (mean_res - correct_res) / correct_res
print("Relative errors: ")
print(relative_errors)

if rounding_mode != "ud" or rounding_mode != "up-down":
    assert np.allclose(
        mean_res, correct_res
    ), "Results of matrix multiplication with MCA not centered on the correct result"
    print(
        "[PASSED] Results of matrix multiplication with MCA centered on the correct result"
    )
else:
    print("[SKIPPED] Test matrix multiplication with MCA centered on the correct result for rounding mode: ", rounding_mode)


assert (
    mca_res.std(axis=0).sum() != 0
), "Results of matrix multiplication with MCA are deterministic"
print("[PASSED] Results of matrix multiplication with MCA are not deterministic")

assert (
    matmul_layer.std(axis=0).sum() != 0
), "Results of Linear layer matrix multiplication with MCA are deterministic"
print(
    "[PASSED] Results of Linear layer matrix multiplication with MCA are not deterministic"
)

assert (
    conv.std(axis=0).sum() != 0
), "Results of convolution operation with MCA are deterministic"
print("[PASSED] Results of convolution with MCA are not deterministic")

assert (
    conv_layer.std(axis=0).sum() != 0
), "Results of Convolution layer with MCA are deterministic"
print("[PASSED] Results of Convolution layer with MCA are not deterministic")