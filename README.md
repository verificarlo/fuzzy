# Fuzzy v0.9.1

[![DOI](https://zenodo.org/badge/218554957.svg)](https://zenodo.org/badge/latestdoi/218554957)
[![Build Fuzzy Environments](https://github.com/verificarlo/fuzzy/actions/workflows/build-fuzzy.yml/badge.svg?branch=master)](https://github.com/verificarlo/fuzzy/actions/workflows/build-fuzzy.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/verificarlo/fuzzy)](https://hub.docker.com/r/verificarlo/fuzzy)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://releases.llvm.org/13.0.0/LICENSE.TXT)

*A fuzzy ecosystem for evaluating the effect of numerical error on computational tools.*

[![Fuzzy Marimo](https://github.com/verificarlo/fuzzy/raw/master/img/fuzzy.png)](./img/fuzzy.png)

## Motivation

Computational analysis has become an essential component of science. The software tools
used bear the weight of the countless models, discoveries, and interventions based
upon them. However, computers were never intended to be perfect, and one doesn't
need to look very far to find examples of where conceptually simple operations
may fail due to floating point arithmetic (e.g. ...

```
$ python3 -c "print(sum([0.001] * 1000))"
1.0000000000000007
```

). While small issues like the one above are unlikely to cause catestrophic failures on
their own, they can cascade over the course of an execution and it isn't uncommon to
find a [plane that requires a power cycle every two months](https://www.theregister.com/2020/04/02/boeing_787_power_cycle_51_days_stale_data)
or an [unstable series that consistently converges to the wrong solution](https://nbviewer.jupyter.org/github/verificarlo/fuzzy/blob/master/tutorial/evaluating_unstable_sequence.ipynb).

*Fuzzy* allows you to study the stability or *trustworthiness* of tools and pipelines.
You start by *instrumenting* libraries in your pipeline which do the bulk of numerical
heavy lifting, then run your tool multiple times, and finally analyze the variability
in your results. This project aims to provide an environment in which the stability of
programs can be evaluated, reducing the overhead on both tool developers and consumers.


## Usage

#### Building & booting the environment
You can get started with *Fuzzy* quite simply, just launch a
[Docker](https://www.docker.com/) container as follows:

```
docker run -ti verificarlo/fuzzy
```

If you're on a shared system and would prefer to use [Singularity](https://sylabs.io/),
that's no problem, just convert the container using the appropriate method for
your system ([e.g.](https://docs.computecanada.ca/wiki/Singularity#Creating_images)).

If you would like to build the environment locally on your system, look at the
Dockerfiles in `docker/base/` to see how installation was performed. At the end of the
build chain, you'll find instrumented versions of `libmath`, `lapack`, `python3`,
`numpy`, and several other recompiled libraries.

An example for how to verify your installation for Python could be the following:
```
$ python3 -c "print([sum([.001]*1000) for _ in range(3)])"
[1.0, 0.9999999999999997, 1.0000000000000007, 1.0000000000000002]
```

#### Adding your software
If your code is written in, say, Python, then you can simply mount your code to
this environment, run it using the contained interpreter, and experince the *:fuzz:*.
If your code loads shared libraries, such as `libmath` or `lapack`, make sure that
they are using the instrumented versions of these libraries made available in
`/usr/local/lib/`. You can check whether this is the case using `ldd </path/to/yourbinary>`.

The next step is to make sure the environment is configured to introduce perturbations
the way you expect. You can start with a configuration which performs perturbations
akin to randomizing machine error with the following:

```
echo "libinterflop_mca.so -m mca --precision-binary32=24 --precision-binary64=53" > $VFC_BACKENDS_FROM_FILE
```

For more usage instructions on how to control how perturbations are introduced
and where they occur within operations, please refer to the
[Verificarlo](https://github.com/verificarlo/verificarlo) repository.

A simple sanity check to verify that your code is using the perturbed libraries
is to dramatically reduce the precision in your configuration by changing the
`precision-binary32` and `precision-binary64` values to something small (e.g. 1),
boot up a debugging session in your environment (e.g. a Python shell, GDB, etc.),
load a math library, and run a basic math function a few times (e.g. `sin(1)`) —
you should get different results if your instrumentation is setup properly.
***Important***: Don't forget to set the precision back to your desired level
prior to performing your experiments! *Fuzzy* should print a log message to the
terminal when you run your commands, including the configuration, so you can verify
that the parameters were properly specified.

#### Fuzzy-libmath

Since version v0.8.0, fuzzy-libmath comes with three modes (standard, quad, and
 mpfr). Internally, the fuzzy-libmath computes the actual result of the math
function using the standard library of the OS and then perturbs the output by
adding MCA noise. Since the accuracy of the `libm` used can vary from one
version to another (see this
[article](https://hal.inria.fr/hal-03141101v2/document)), one
can use higher precision to ensure accurate intermediate computations.
These modes specify the library used:
- `standard`: uses the standard libm provided by the OS. (fastest)
- `quad`: uses the libquadmath.so library
- `mpfr`: uses the MPFR library with 113 bits of precision, equivalent to
  the binary128 precision (slowest)

Note that a higher precision implies a larger slowdown. The `standard` mode is
the fastest and can be used if one does not require high accuracy. To switch
from one version to another, please use the `set-fuzzy-libmath` tool already
installed in the docker image as follow:

```
usage: set-fuzzy-libmath [-h] --version {no-fuzzy,standard,quad,mpfr}

optional arguments:
  -h, --help            show this help message and exit
  --version {no-fuzzy,standard,quad,mpfr}

Fuzzy libmath version to use:
    - no-fuzzy: Disable fuzzy libmath
    - standard: Use the standard libmath available on the system.
                Fastest instrumentation but possibly not accurate
    - quad:     Use the libquadmath for intermediate results.
                Slower than the standard version but more accurate.
    - mpfr:     Use the mpfr library for intermediate results.
                Slowest version but gives the correct rounding.
```

#### Using Fuzzy in Multi-stage builds
Fuzzy provides a set of recompiled shared objects and tools that facilitate adding
Monte Carlo Arithmetic to tools. If you've got a Docker container which relies on
some of these libraries, you can easily add *Fuzzy* with a [Multi-stage Docker build](https://docs.docker.com/develop/develop-images/multistage-build/).

For example:

```
FROM verificarlo/fuzzy:latest as fuzzy

# Your target image
FROM user/image:version

# Copy libmath fuzzy environment from fuzzy image, for example
RUN mkdir -p /opt/mca-libmath/{standard,quad,mpfr}
COPY --from=${2} /opt/mca-libmath/set-fuzzy-libmath.py /usr/local/bin/set-fuzzy-libmath
COPY --from=${2} /opt/mca-libmath/standard/libmath.so /opt/mca-libmath/standard/libmath.so
COPY --from=${2} /opt/mca-libmath/quad/libmath.so /opt/mca-libmath/quad/libmath.so
COPY --from=${2} /opt/mca-libmath/mpfr/libmath.so /opt/mca-libmath/mpfr/libmath.so
COPY --from=${2} /usr/local/lib/libinterflop* /usr/local/lib/

# If you will also want to recompile more libraries with verificarlo, add these lines
COPY --from=fuzzy /usr/local/bin/verificarlo* /usr/local/bin/
COPY --from=fuzzy /usr/local/include/* /usr/local/include/

# Preloading the instrumented shared library
ARG FUZZY_LIBMATH_VERSION=standard
RUN set-fuzzy-libmath --version=${FUZZY_LIBMATH_VERSION}

ENV VFC_BACKENDS 'libinterflop_mca.so --precision-binary32=24 --precision-binary64=53 --mode=mca'
```

#### Running Fuzzy workflows
In the context of *Fuzzy* experiments, it is important to remember that by default
each execution will be evaluated with a unique random state, meaning that when you
run it again you may get slightly (or very) different results. If your goal is to
characterize the variability in your results, or obtain a robust estimate of the
"true" mean answer, you will need to then run your tool multiple times and compare
each execution.

It's also important to remember that the execution time will be increased when using
*Fuzzy*, as compared to running tools in a determinitic environment. Depending on
the tool, the instrumentation, and the MCA mode, this additional overhead may range
from negligible to the order of a ***30x*** slowdown.

Included in the references below are some references which can be referred to when
deciding how many perturbations to run, how to consider groups of results, and
demonstrating the differences in overhead that may exist between different
instrumentations.

#### Quick overview of Monte Carlo Arithmetic
A detailed explanation of Monte Carlo Arithmetic can be found in the references below
or the [Verificarlo repository](https://github.com/verificarlo/verificarlo). In short,
here is some terminology to get you started.

In this form of stochastic arithmetic you have three modes for perturbing your
floating-point operations `x = a op b` where `op` is in `{+,-,*,/}`:

1. Random Rounding (RR): `x = inexact(a op b)`
2. Precision Bounding (PB): `x = inexact(a) op inexact(b)`
3. Full MCA (MCA): `x = inexact(inexact(a) op inexact(b))`

In this implementation, the `inexact` operation is the addition of a `0`-centered
uniform random variable at the target bit of precision.

#### Common failures
As you become familiar with *Fuzzy*, you may run into some of the following common
sources of error in your (or other) software:

- Fuzzy not running on your system, and giving `Illegal instruction` errors (likely exit-code `132`)? This is probably because our environments were built in a different architecture than yours! We tried to turn off as many optimizations as we could, increasing the portability of these images, but sometimes libraries don't listen to instructions very well... Try rebuilding the images on your local machine. to fix the problem. To our knowledge, `Scipy` is the first package in the install chain which has some dependencies that may ignore the optimization-disabling compiler flags, so you could try starting your rebuild from the `Numpy` image.

- When using MCA or PB modes of perturbation, operations which rely on integer
values which happen to be stored in floating point containers may crash. For instance,
imagine you're creating an array and store the desired length as `3.0` instead of `3`;
introduced perturbations may shift your length away from the exact-value of `3.0`, and
then your tool could (justifiably) crash when trying to allocate a `2.99..` element array.
You can fix these types of bugs by simply casting your length variable to an integer.

- In cases where piecewise approximations are used to solve complex functions (e.g.
[the sin function in libc](https://github.com/lattera/glibc/blob/master/sysdeps/ieee754/dbl-64/s_sin.c).),
it is possible that perturbations will trigger distinct branching and result in
possibly large discontinuity between results. *Fuzzy* appraches instrumenting these
libraries via wrappers which ultimately perturb the function inputs and outputs,
rather than the internal arithmetic operations which may take place. An example
of this can be found for [`libmath`](/docker/resources/libmath/).


## Contributing

For instructions on how to contribute, please refer to the [Contribution Guide](.github/CONTRIBUTING.md).

## Presentation
If you prefer a visual illustration of everything we've written above, feel free to check-out [the slides
we recently presented at Scipy2021](https://figshare.com/articles/presentation/Fuzzy_Environments/14991825)!

## References
The *Fuzzy* ecosystem has emerged from — and been used in — several scientific
publications. Below is a list of papers which present the techniques used, the
tools which have been developed accordingly, and demonstrate how decision-making
and applications can be built atop them:

> Parker, Douglas Stott, Brad Pierce, and Paul R. Eggert. "Monte Carlo arithmetic: how to gamble with floating point and win." Computing in Science & Engineering 2.4 (2000): 58-68.
>
> Frechtling, Michael, and Philip HW Leong. "Mcalib: Measuring sensitivity to rounding error with monte carlo programming." ACM Transactions on Programming Languages and Systems (TOPLAS) 37.2 (2015): 1-25.
>
> C. Denis, P. De Oliveira Castro and E. Petit,  "Verificarlo: Checking Floating Point Accuracy through Monte Carlo Arithmetic," in 2016 IEEE 23nd Symposium on Computer Arithmetic (ARITH), Silicon Valley, CA, USA, 2016 pp. 55-62.
>
> Chatelain, Yohan, et al. "VeriTracer: Context-enriched tracer for floating-point arithmetic analysis." 2018 IEEE 25th Symposium on Computer Arithmetic (ARITH). IEEE, 2018.
>
> Kiar, Gregory, et al. "Comparing perturbation models for evaluating stability of neuroimaging pipelines." The International Journal of High Performance Computing Applications 34.5 (2020): 491-501.
>
> Sohier, Devan, et al. "Confidence Intervals for Stochastic Arithmetic." ACM Transactions on Mathematical Software (TOMS) 47.2 (2021): 1-33.
>
> Kiar, Gregory, et al. "Data Augmentation Through Monte Carlo Arithmetic Leads to More Generalizable Classification in Connectomics." bioRxiv (2020).

## License
The *Fuzzy* copyright belongs to all contributors of this repository, and it is
[licensed](./LICENSE) for public use under the same terms as the
[LLVM project](https://foundation.llvm.org/relicensing/LICENSE.txt), which is a
modified version of the Apache 2.0 license.
