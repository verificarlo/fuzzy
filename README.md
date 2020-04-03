[![Fuzzy Marimo](./img/fuzzy.png)](https://github.com/gkiar/fuzzy/img/fuzzy.png)

# Fuzzy 

[![Build Status](https://travis-ci.org/gkiar/fuzzy.svg?branch=master)](https://travis-ci.org/gkiar/fuzzy)
[![Docker Pulls](https://img.shields.io/docker/pulls/gkiar/fuzzy)](https://hub.docker.com/r/gkiar/fuzzy)
[![GPL Licensed](https://img.shields.io/badge/license-GPL-blue)](./LICENSE)


*A fuzzy ecosystem for evaluating the stability of your computational tools.*


## Motivation

While computational pipelines have become essential for processing large quantities of data,
the stability or *trustworthiness* of tools often remains unknown. Limitations of floating point
data and subsequent arithmetic show their colours in even [incredibly simple operations](./fuzzy/tutorial/inaccuracies_everywhere.ipynb).
While the linked example demonstrates unexpected results that are relatively minor, this effect
can have cascading impact that lead to [quantifiable and significant errors](https://nbviewer.jupyter.org/github/gkiar/fuzzy/blob/master/fuzzy/tutorial/evaluating_unstable_sequence.ipynb).
Though the examples above can be evaluated based on their relative error compared to an expected
correct value, many real-world applications have unknown "truth", and thus can't be evaluated in
this way.

This project aims to provide an environment in which the stability of programs can be evaluated,
so that developers may evaluate the trustworthiness of their tools even in the absense of truth.


## Usage

*Coming soon*!

## Supported Languages/Libraries

- BLAS
- LAPACK
- Python3.6.5
- Numpy (Python3.6.5)
- Pytorch (Python3)
- Libmath


## Build Instructions

*Coming soon*!

## Contributing

*Coming soon*!

