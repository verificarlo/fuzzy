#!/bin/bash

export VFC_BACKENDS="libinterflop_mca.so --mode=mca --precision-binary64=53 --precision-binary32=24"
export LD_PRELOAD=$PWD/../libmath.so

declare -A signature_a
declare -A type_a
signature_a=([univar]="univariate" [bivar]="bivariate" [lgamma_r]="lgamma_r" [sincos]="sincos")
type_a=([float]="binary32" [double]="binary64")

export VFC_BACKENDS_LOGGER="False"
export VFC_BACKENDS_SILENT_LOAD="True"

function assert_noise() {
    ./check_result.py outputs
    if [[ $? != 0 ]]; then
        echo "Failed"
        exit 1
    else
        echo "Successed"
    fi
}

function check_compilation() {
    if [[ $? != 0 ]]; then
        echo "Compilation failed"
        exit 1
    fi
}

function check_file_exist() {
    if [[ ! -f $1 ]]; then
        echo "File ${1} does not exist"
        exit 1
    fi
}

function compile() {
    TYPE=$1
    SIG=$2
    FUNCTION=$3
    echo "gcc test.c -lm -DREAL=$TYPE -D$SIG -DFUNCTION=$FUNCTION -o test"
    gcc -g test.c -lm -DREAL=$TYPE -D$SIG -DFUNCTION=$FUNCTION -o test
    check_compilation
}

function run() {
    LD_PRELOAD=$LD_PRELOAD ./test $* > outputs
}

IFS=" "
for TYPE in "${!type_a[@]}"; do
    FILE=data/"math-functions-${type_a[$TYPE]}-${signature_a[univar]}.txt"
    while read -r FUNCTION POINT ; do
        echo "Evalue $FUNCTION on ${POINT}"
        compile $TYPE UNIVAR $FUNCTION
        run $POINT
        assert_noise
    done < $FILE
done

IFS=" "
for TYPE in "${!type_a[@]}"; do
    FILE=data/"math-functions-${type_a[$TYPE]}-${signature_a[bivar]}.txt"
    while read -r FUNCTION POINT1 POINT2 ; do
        echo "Evalue $FUNCTION on ${POINT}"
        compile $TYPE BIVAR $FUNCTION
        run $POINT1 $POINT2
        assert_noise
    done < $FILE
done

IFS=" "
for TYPE in "${!type_a[@]}"; do
    FILE=data/"math-functions-${type_a[$TYPE]}-${signature_a[sincos]}.txt"
    while read -r FUNCTION POINT ; do
        echo "Evalue $FUNCTION on ${POINT}"
        compile $TYPE SINCOS $FUNCTION
        run $POINT
        assert_noise
    done < $FILE
done

IFS=" "
for TYPE in "${!type_a[@]}"; do
    FILE=data/"math-functions-${type_a[$TYPE]}-${signature_a[lgamma_r]}.txt"
    check_file_exist $FILE
    while read -r FUNCTION POINT ; do
        echo "Evalue $FUNCTION on ${POINT}"
        compile $TYPE LGAMMA_R $FUNCTION
        run $POINT
        assert_noise
    done < $FILE
done

