import scipy
import scipy.linalg
import numpy as np


def test_inv():
    ret = np.unique(([scipy.linalg.inv([[1, 2], [3, 4]]) for _ in range(100)]))
    assert ret.size != 4


if "__main__" == __name__:
    test_inv()
