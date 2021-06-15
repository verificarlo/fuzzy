#!/bin/env python3

import numpy as np
import sys


def load_value(filename):
    value = np.loadtxt(filename, dtype=np.float64)
    return value


def check_std(value):
    return np.all(np.std(value, dtype=np.float64, axis=0) != 0)


if __name__ == '__main__':
    filename = sys.argv[1]
    value = load_value(filename)
    has_variance = check_std(value)

    if has_variance:
        sys.exit(0)
    else:
        print("No variance found")
        sys.exit(1)
