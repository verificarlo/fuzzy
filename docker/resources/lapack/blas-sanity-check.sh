#!/bin/bash

# Set VIRTUAL_ENV to the /usr/local directory if it is not set
if [ -z "$VIRTUAL_ENV" ]; then
    export VIRTUAL_ENV=/usr/local
fi

gcc test_blas.c -o test_blas -lblas -llapack -L$VIRTUAL_ENV/lib -I$VIRTUAL_ENV/include

for i in {1..10}; do
    ./test_blas >test_blas.$i.txt
done

for i in {1..10}; do
    for j in {1..10}; do
        RES=$(diff test_blas.$i.txt test_blas.$j.txt)
        if [[ $i -ne $j && -n $RES ]]; then
            echo "[PASS] test_blas.$i.txt and test_blas.$j.txt are different"
            exit 0
        fi
    done
done

echo "[FAIL] No difference found in the output of the BLAS test"
exit 1
