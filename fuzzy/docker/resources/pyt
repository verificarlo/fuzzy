VFC_BACKENDS="libinterflop_mca.so" python -c "
import torch
import pickle

N_SAMPLES = 30

torch.manual_seed(0)
a = torch.rand(5, 5)
b = torch.rand(5, 5)

res = []
for _ in range(N_SAMPLES):
  res.append(a @ b)

with open('fuzzy-pytorch_mca_results.pickle', 'wb') as file:
  pickle.dump(torch.stack(res), file)
"
VFC_BACKENDS="libinterflop_ieee.so" python -c "
import torch
import pickle

torch.manual_seed(0)
a = torch.rand(5, 5)
b = torch.rand(5, 5)
correct_res = a @ b

with open('fuzzy-pytorch_mca_results.pickle', 'rb') as file:
  mca_res = pickle.load(file)

mean_res = mca_res.mean(dim=0)
relative_errors = (mean_res - correct_res) / correct_res
print('Relative errors: ')
print(relative_errors)

assert torch.allclose(mean_res, correct_res), 'Results of matrix multiplication with MCA not centered on the correct result'
print('[PASSED] Results of matrix multiplication with MCA centered on the correct result')
assert mca_res.std(dim=0).sum() != 0, 'Results of matrix multiplication with MCA are deterministic'
print('[PASSED] Results of matrix multiplication with MCA are not deterministic')
"
