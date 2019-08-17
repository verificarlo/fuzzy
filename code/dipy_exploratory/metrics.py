#!/usr/bin/env python

import numpy as np


############################
#   Define distance functions
############################
# Frobenius Norm
def fro(x, y=None):
    y = np.zeros_like(x) if y is None else y
    return np.linalg.norm(x - y, ord='fro')


# Mean Squared Error
def mse(x, y=None):
    y = np.zeros_like(x) if y is None else y
    return np.mean((x - y)**2)


# Sum of Squared Differences
def ssd(x, y=None):
    y = np.zeros_like(x) if y is None else y
    return np.sum((x - y)**2)


metrics = {'fro': fro, 'mse': mse, 'ssd': ssd}
met_names = {'mse': "Mean Squared Error",
             'ssd': "Sum of Square Differences",
             'fro': "Frobenius Norm"}
