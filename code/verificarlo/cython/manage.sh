#!/bin/bash

# Clean up old build files
if [ "$1" == "clean" ]
then
    rm -r ./*.ll ./*.c ./*.so build
    exit 0
fi

# Test build
if [ "$1" == "test" ]
then
    python3 -c "from mca_ext import myf as f; f($2)"
    exit 0
fi

# Otherwise, build...
# Determine and set compilation mode
if [ "$1" == "mca" ]
then
    str="verificarlo"
else
    str="gcc"
fi
echo $str

export CC=$str
export FC=$str
export LD=$str

# Build library
python3 setup.py build_ext --inplace
