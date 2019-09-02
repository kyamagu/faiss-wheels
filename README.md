# faiss-wheels

[![Travis-CI](https://img.shields.io/travis/kyamagu/faiss-wheels.svg)](https://travis-ci.org/kyamagu/faiss-wheels)
[![PyPI](https://img.shields.io/pypi/v/faiss-cpu?label=faiss-cpu)](https://pypi.org/project/faiss-cpu/)
[![PyPI](https://img.shields.io/pypi/v/faiss-gpu?label=faiss-gpu)](https://pypi.org/project/faiss-gpu/)

faiss python wheel packages based on multibuild.

- [faiss](https://github.com/facebookresearch/faiss)
- [multibuild](https://github.com/matthew-brett/multibuild)

## Overview

This repository provides scripts to create wheel packages for the
[faiss](https://github.com/facebookresearch/faiss) library.

- Builds CPU-only or CUDA-8.0+ compatible wheels.
- Bundles OpenBLAS in Linux using static linking and `auditwheel`
- Uses Accelerate framework on macOS
- CUDA runtime and cuBLAS are statically linked

There is also a source package to customize the build process.

### Prerequisite

On macOS, install `libomp` via Homebrew to use the wheel.

```bash
brew install libomp
```

### Install

Install CPU-only version:

```bash
pip install faiss-cpu
```

Or, install CUDA-8.0+ compatible version:

```bash
pip install faiss-gpu
```

Note that CUDA toolkit is not required to run the GPU wheel. Only NVIDIA drivers
should be installed to use gpu index. One can also install faiss-gpu to run
cpu-only methods without a NVIDIA driver.

## Building source package

If there is a custom built faiss library in the system, build source package for
the best performance.

### Prerequisite

The sdist package can be built when faiss is already built and installed.

```bash
cd faiss
aclocal \
    && autoconf \
    && ./configure \
    && make -j4 \
    && make install
```

See the official
[faiss installation instruction](https://github.com/facebookresearch/faiss/blob/master/INSTALL.md)
for more on how to build and install faiss.

For building sdist, swig 3.0.12 or later needs to be available.

### Linux

By default, the following builds and installs the faiss-cpu package.

```bash
pip install --no-binary :all: faiss-cpu
```

If faiss is built with CUDA, the following builds a CUDA compatible package.

```bash
pip install --no-binary :all: faiss-gpu
```

CUDA installation is specified by `CUDA_HOME` environment variable, which by
default is `/usr/local/cuda`.

Header locations and link flags can be customized by
`FAISS_INCLUDE` and `FAISS_LDFLAGS` environment variables for building sdist.
It is also possible to statically link dependent libraries:

```bash
export FAISS_LDFLAGS='-l:libfaiss.a -l:libopenblas.a -lgfortran -lcudart_static -lcublas_static -lculibos'
pip install --no-binary :all: faiss-gpu
```

### macOS

On macOS, install `llvm` and `libomp` via Homebrew to build with OpenMP support.
Mac has Accelerate framework for BLAS implementation. Note that compiler flags
can only use absolute path for sdist package. CUDA is not supported on macOS.

```bash
brew install llvm libomp
export CC=/usr/local/opt/llvm/bin/clang
export CXX=/usr/local/opt/llvm/bin/clang++
export FAISS_INCLUDE=/usr/local/include/faiss
export FAISS_LDFLAGS='-lfaiss -framework Accelerate'
pip install --no-binary :all: faiss-cpu
```
