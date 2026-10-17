# Fuzzy

Fuzzy provides numerical libraries compiled with [Verificarlo](https://github.com/verificarlo/verificarlo)
and its PRISM backend. Run a calculation repeatedly with stochastic rounding to
measure its sensitivity to rounding errors, or select a plain build for comparison.

The v2.7.0 recipes build one image per x86-64 CPU level. Each contains `ieee`
and `prism` builds of LAPACK, CPython, NumPy, SciPy, scikit-learn, PyTorch,
torchaudio, torchvision and libm. Select each package independently at run time.

## Choose an image

| CPU level | Image tag | Alias |
| --- | --- | --- |
| x86-64 baseline (SSE2) | `v2.7.0-x86-64-v1` | `v2.7.0-sse2` |
| x86-64-v2 (SSE4.2) | `v2.7.0-x86-64-v2` | `v2.7.0-sse4` |
| x86-64-v3 (AVX2) | `v2.7.0-x86-64-v3` | `v2.7.0-avx2` |
| x86-64-v4 (AVX-512) | `v2.7.0-x86-64-v4` | `v2.7.0-avx512` |

Choose a level your CPU supports. Use v1 when portability matters; `latest`
points to v1 after all four release images pass validation.

```bash
docker run --rm -it verificarlo/fuzzy:v2.7.0-x86-64-v3
fuzzy list
fuzzy use lapack=ieee numpy=prism
python3 script.py
```

The per-stack tags (`-lapack`, `-lapack-python…`, `-numpy`, `-scipy`,
`-sklearn`, `-pytorch…`) are legacy. Their recipes and tags remain available;
see [the legacy guide](LEGACY.md). New releases publish the CPU-level tags.

## Select builds

Every package defaults to `prism`, with stochastic rounding enabled.

```bash
fuzzy use python=ieee libm=ieee lapack=ieee numpy=prism
fuzzy run lapack=prism -- python3 script.py
eval "$(fuzzy env python=prism)"
```

`fuzzy use` changes native library symlinks and installs the chosen Python
wheels with `uv`. `fuzzy run` and `fuzzy env` select native libraries and the
interpreter without writing to the image. On read-only images, including
Apptainer, create a writable Python environment to select Python wheels:

```bash
uv venv ~/fuzzy-env --python /opt/fuzzy/python/3.12/bin/python3
fuzzy use --python ~/fuzzy-env numpy=ieee scipy=prism
fuzzy run python=ieee lapack=ieee libm=ieee -- ~/fuzzy-env/bin/python script.py
```

Mount your own code with `docker run -v "$PWD:/workdir" …`, or derive an
image with `FROM verificarlo/fuzzy:v2.7.0-x86-64-v3`.

## Check stochastic rounding

CPython 3.12 uses compensated summation for `sum()` of floats, which can
recover rounding errors. Use an explicit loop to see variation:

```bash
python3 -c '
for run in range(3):
    s = 0.0
    for _ in range(1000):
        s += 0.001
    print(s.hex())'
```

PRISM changes inexact operations; exact operations stay exact. Run your real
calculation several times and compare its outputs. Fix the seed to reproduce
one rounding sequence, select round-to-nearest, or reduce virtual precision:

```bash
VFC_BACKENDS="libinterflop_prism.so --mode=sr --seed=42" python3 script.py
VFC_BACKENDS="libinterflop_prism.so --mode=rn" python3 script.py
VFC_BACKENDS="libinterflop_prism.so --precision-binary64=40" python3 script.py
```

PRISM's round-to-nearest can differ from the plain build in the last bits.
MCA modes such as precision bounding are documented in the legacy guide;
the v2.7.0 package recipes use PRISM stochastic rounding.

## Build and validate

```bash
docker/fuzzy/build.sh v3 podman  # or docker; v1, v2 and v4 also supported
```

Building runs the compiled code, so v4 requires an AVX-512 builder. CI uses
`[self-hosted, Linux, X64, avx512]` for v4 and hosted runners for v1–v3.
Each build tests both flavors, mixed selections, runtime sharing and linking,
round-to-nearest agreement, stochastic variation and ISA limits. CI also runs
v1–v3 under Intel SDE with older CPU profiles before publishing.

See [the image guide](docker/fuzzy/README.md) for package versions, Python
wheel indexes, supported CPU backends and build details. A hosted wheel index
is optional; all wheels ship inside each image.

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
>
> Chatelain, Yohan, et al. "PyTracer: Automatically profiling numerical instabilities in Python." IEEE Transactions on Computers (2022).
>
> Des Ligneris, Morgane, et al. "Reproducibility of tumor segmentation outcomes with a deep learning model." 2023 IEEE 20th International Symposium on Biomedical Imaging (ISBI). IEEE, 2023.
> 
> Pepe, Inés Gonzalez, et al. "Numerical Uncertainty of Convolutional Neural Networks Inference for Structural Brain MRI Analysis." International Workshop on Uncertainty for Safe Utilization of Machine Learning in Medical Imaging. Cham: Springer Nature Switzerland, 2023.
>
> Chatelain, Yohan, et al. "A numerical variability approach to results stability tests and its application to neuroimaging." arXiv preprint arXiv:2307.01373 (2023).
> 
> Vila, Gaël, et al. "The Impact of Hardware Variability on Applications Packaged with Docker and Guix: a Case Study in Neuroimaging." (2024).
>
> Gonzalez Pepe, Inés, et al. "Numerical stability of DeepGOPlus inference." Plos one 19.1 (2024): e0296725.

## License
The *Fuzzy* copyright belongs to all contributors of this repository, and it is
[licensed](./LICENSE) for public use under the same terms as the
[LLVM project](https://foundation.llvm.org/relicensing/LICENSE.txt), which is a
modified version of the Apache 2.0 license.
