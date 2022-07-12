#!/bin/env python3

from msilib.schema import Error
import numpy as np
import sys


def float_handler(x):
    try:
        return float(x)
    except ValueError:
        return float.fromhex(x)
    except:
        raise Error(x)


def load_value(filename):
    value = [[float_handler(x) for x in l.strip().split()]
             for l in open(filename)]
    return np.array(value)


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
