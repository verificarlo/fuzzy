> These instructions are copied from when this was a standalone project.

# libmath Monte-Carlo Arithmetic model
We are evaluating the pipeline stability by applying noise to mathematical functions 
using the library call interposition technique. This project aims to study whether 
the MCA method is truly a good perturbation model for evaluating pipeline stability 
across the operating systems.

## Usage example

1) Install the last version of [Verificarlo](https://github.com/verificarlo/verificarlo)

2) Create instrumented shared math library:
```
git clone https://github.com/big-data-lab-team/MCA-libmath.git /tmp/mca-libmath/
cd /tmp/mca-libmath/src/
make
make test
```

3) Export Linux `LD_PRELOAD` environment variable by running:
```
export LD_PRELOAD=/tmp/mca-libmath/src/libmath.so
```

4) Set the virtual precision and instrumentation mode of Verificarlo by running:
```
export VFC_BACKENDS="libinterflop_mca.so --precision-binary32 <p1> --precision-binary64 <p2> --mode <m>"
```

5) Run your pipeline

## Usage example through the Docker image

We created a docker base image, including the steps (1-4) mentioned above. It is available at https://hub.docker.com/r/salari/fuzzy/ubuntu-libmath-base.

Running a simple test script in which calculates the standard deviation of several mca samples of sin() function:

```
docker pull verificarlo/fuzzy
docker run -w /tmp/mca-libmath/tests/  ubuntu-libmath-base /bin/bash test.sh
```
