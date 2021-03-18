#!/bin/bash

set -ex

if [ -n "$VERIFICARLO_VERSION" ]; then
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends libmpfr-dev libtool
  pip install bigfloat

  git clone https://github.com/verificarlo/verificarlo
  cd verificarlo
  git checkout 09b24e04797dcf849ca1080d8d06e6d89a14dc65
  export PATH="$PATH:/usr/lib/llvm-9/bin/"
  ./autogen.sh
  ./configure --without-flang CC=gcc-7 CXX=g++-7
  make
  sudo make install
  cd ..
  rm -rf verificarlo

  # Cleanup package manager
  apt-get autoclean && apt-get clean
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
fi
