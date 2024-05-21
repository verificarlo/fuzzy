import re
import numpy as np
from sklearn.decomposition import PCA


def test_pca():
    X = np.array([[-1, -1], [-2, -1], [-3, -2], [1, 1], [2, 1], [3, 2]])
    pca = PCA(n_components=2)
    res = [pca.fit(X).singular_values_ for i in range(100)]
    ret = np.unique(res)
    assert ret.size != 2


if "__main__" == __name__:
    test_pca()
