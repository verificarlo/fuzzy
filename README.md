# Fuzzy 
[![Build Status](https://travis-ci.org/gkiar/fuzzy.svg?branch=master)](https://travis-ci.org/gkiar/fuzzy)
[![Docker Pulls](https://img.shields.io/docker/pulls/gkiar/fuzzy)](https://hub.docker.com/r/gkiar/fuzzy)
[![GPL Licensed](https://img.shields.io/badge/license-GPL-blue)](./LICENSE)

*A fuzzy ecosystem for evaluating the stability of your computational tools.*

## Motivation

While computational pipelines have become essential for processing large quantities of data,
the stability or *trustworthiness* of tools often remains unknown. Limitations of floating point
data and subsequent arithmetic show their colours in even
[incredibly simple operations](./fuzzy/tutorial/inaccuracies_everywhere.ipynb).

## Usage

We have produced man

## Supported Languages/Libraries

- BLAS
- LAPACK
- Python3.6.5
- Numpy (Python3.6.5)
- Pytorch (Python3)
- Libmath


## Build Instructions

Try building the container as follows:

    docker build -t gkiar/fuzzy-python .
