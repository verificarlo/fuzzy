# Fuzzy

[![Build Fuzzy Environments](https://github.com/verificarlo/fuzzy/actions/workflows/build-fuzzy.yml/badge.svg?branch=master)](https://github.com/verificarlo/fuzzy/actions/workflows/build-fuzzy.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/verificarlo/fuzzy)](https://hub.docker.com/r/verificarlo/fuzzy)
[![GPL Licensed](https://img.shields.io/badge/license-GPL-blue)](./LICENSE)

*A fuzzy ecosystem for evaluating the effect of numerical error on computational tools.*

[![Fuzzy Marimo](https://github.com/verificaro/fuzzy/raw/master/img/fuzzy.png)](./img/fuzzy.png)

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
Dockerfiles in `docker/base/` to see how installation was performed.

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
prior to performing your experiments!

#### Running Fuzzy workflows
In the context of *fuzzy* experiments, it is important to remember that by default
each execution will be evaluated with a unique random state, meaning that when you
run it again you may get slightly (or very) different results. If your goal is to
characterize the variability in your results, or obtain a robust estimate of the
"true" mean answer, you will need to then run your tool multiple times and compare
each execution.

It's also important to remember that the execution time will be increased when using
*Fuzzy*, as compared to running tools in a determinitic environment. Depending on
the tool, the instrumentation, and the MCA mode, this additional overhead may range
from negligible to the order of a ***100x*** slowdown.

Included in the references below are some references which can be referred to when
deciding how many perturbations to run, how to consider groups of results, and
demonstrating the differences in overhead that may exist between different
instrumentations.

#### Common failures
As you become familiar with *Fuzzy*, you may run into some of the following common
sources of error in your (or other) software:

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

For instructions on how to contribute, please refer to the [Contribution Guide](contributing.md).

## References
The *Fuzzy* ecosystem has emerged-from and been used-in several scientific
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
licensed for public use under the same terms as the [LLVM project](https://foundation.llvm.org/relicensing/LICENSE.txt),
which is a modified version of the Apache 2.0 license.