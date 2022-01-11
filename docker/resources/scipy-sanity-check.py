import scipy
import scipy.linalg


def test_det():
    ret = set([scipy.linalg.det([[1, 2], [3, 4]]) for _ in range(100)])
    assert len(ret) != 1


if "__main__" == __name__:
    test_det()
