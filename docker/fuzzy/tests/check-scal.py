#!/usr/bin/env python3
"""Check BLAS scaling at unroll boundaries and with non-unit strides."""
import ctypes as C

blas = C.CDLL('libblas.so.3')
for name, scalar in (('sscal_', C.c_float), ('dscal_', C.c_double)):
    function = getattr(blas, name)
    function.argtypes = [C.POINTER(C.c_int), C.POINTER(scalar),
                         C.POINTER(scalar), C.POINTER(C.c_int)]
    function.restype = None
    for length in (-1, 0, 1, 4, 5, 6, 13, 33):
        for stride in (0, 1, 2, 3):
            for factor in (0.0, 1.0, 1.25, -1.5):
                # Dyadic inputs/products are exact in both precisions, so
                # this tests indexing without PRISM tie-breaking differences.
                count = max(1, length) * max(1, stride) + 8
                values = [scalar(i / 16 - .75).value for i in range(count)]
                expected = list(values)
                if length > 0 and stride > 0:
                    for i in range(length):
                        expected[i * stride] = scalar(factor * values[i * stride]).value
                array = (scalar * count)(*values)
                n, inc, alpha = C.c_int(length), C.c_int(stride), scalar(factor)
                function(C.byref(n), C.byref(alpha), array, C.byref(inc))
                assert list(array) == expected, (name, length, stride, factor)
    print(f'[PASS] {name}: small lengths, unroll boundaries, strides and padding')
