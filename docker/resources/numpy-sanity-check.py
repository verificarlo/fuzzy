#!/usr/bin/env python3

import numpy as np


def test_instrumentation():
    x = np.full(10000, 0.1, dtype=np.float64)
    res = len({np.add.reduce(x).hex() for _ in range(100)})
    assert res != 1


def test_instrumentation_add():
    x = np.full(1000, 0.1, dtype=np.float64)
    vals = [np.add.reduce(x).hex() for _ in range(100)]
    assert len(set(vals)) != 1


def test_instrumentation_multiply():
    x = np.full(1000, 0.1, dtype=np.float64)
    vals = [(x * x).sum().hex() for _ in range(100)]
    assert len(set(vals)) != 1


def test_blas_instrumentation():
    a = np.full((64, 64), 0.1, dtype=np.float64)
    b = np.full((64, 64), 0.2, dtype=np.float64)
    vals = [np.dot(a, b)[0, 0].hex() for _ in range(100)]
    assert len(set(vals)) != 1


def test_vecto():
    """[Test vectorization is handled properly]"""
    x = np.array(range(4), dtype=np.float64)
    z = [i**2 for i in range(4)]
    assert (x**2 == z).all()


def test_arange():
    """[Test that PyArray_Arange is not instrumented]"""
    sizes = all([len(np.linspace(0, 1, 10)) == 10 for i in range(100)])
    assert sizes


if "__main__" == __name__:
    test_vecto()
    test_arange()
