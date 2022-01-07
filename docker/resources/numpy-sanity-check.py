#!/usr/bin/env python3

import numpy as np


def test_instrumentation():
    """[Test numpy is instrumented properly]"""
    res = len(set([np.sum([0.1] * 1000) for i in range(100)]))
    assert res != 1


def test_vecto():
    """[Test vectorization is handled properly]"""
    x = np.array(range(4), dtype=np.float64)
    z = [i ** 2 for i in range(4)]
    assert (x ** 2 == z).all()


def test_arange():
    """[Test that PyArray_Arange is not instrumented]"""
    sizes = all([len(np.linspace(0, 1, 10)) == 10 for i in range(100)])
    assert sizes


if "__main__" == __name__:
    test_vecto()
    test_arange()
