#!/bin/bash
# libprism-static.so and libprism-dynamic.so call Highway (hwy::...) without
# listing libhwy.so as a dependency. That works when the program itself links
# libhwy, as programs built by verificarlo-c do. But when an uninstrumented
# program, such as the ieee CPython, dlopens the first instrumented library
# (a prism NumPy or LAPACK), libhwy is only in that library's local scope,
# and loading libinterflop_prism.so fails ("undefined symbol:
# hwy::GetChosenTarget"); Verificarlo then runs without a backend. Add the
# missing dependency.
set -euo pipefail
for lib in /usr/local/lib/libprism-static.so /usr/local/lib/libprism-dynamic.so; do
    lib=$(readlink -f "$lib")
    if ! readelf -d "$lib" | grep -q 'NEEDED.*\[libhwy\.so\]'; then
        patchelf --add-needed libhwy.so "$lib"
    fi
done
