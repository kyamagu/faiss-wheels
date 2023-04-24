# faiss-wheels

[![Build](https://github.com/kyamagu/faiss-wheels/actions/workflows/build.yml/badge.svg)](https://github.com/kyamagu/faiss-wheels/actions/workflows/build.yml)
[![PyPI](https://img.shields.io/pypi/v/faiss-cpu?label=faiss-cpu)](https://pypi.org/project/faiss-cpu/)
[![PyPI](https://img.shields.io/pypi/v/faiss-gpu?label=faiss-gpu)](https://pypi.org/project/faiss-gpu/)

faiss python wheel packages.

- [faiss](https://github.com/facebookresearch/faiss)

## Overview

This repository provides scripts to build wheel packages for the
[faiss](https://github.com/facebookresearch/faiss) library.

- Builds CPU-only version with [cibuildwheel](https://github.com/pypa/cibuildwheel/).
- Bundles OpenBLAS in Linux/Windows
- Uses Accelerate framework in macOS

There is also a source package to customize the build process.

> **Note**
> GPU package has been supported until version 1.7.2, but is not available since version 1.7.3 due to [the PyPI limitation](https://github.com/kyamagu/faiss-wheels/issues/57).

### Install

Install a binary package by:

```bash
pip install faiss-cpu
```

## Building source package

If there is a custom built faiss library in the system, build source package for
the best performance.

### Prerequisite

The source package assumes faiss is already built and installed in the system.
Build and install the faiss library first.

```bash
cd faiss
cmake . -B build -DFAISS_ENABLE_GPU=OFF -DFAISS_ENABLE_PYTHON=OFF -DFAISS_OPT_LEVEL=avx2
cmake --build build --config Release -j
cmake --install build install
cd ..
```

See the official
[faiss installation instruction](https://github.com/facebookresearch/faiss/blob/master/INSTALL.md)
for more on how to build and install faiss.

For building sdist, swig 3.0.12 or later needs to be available.

### Building a wheel package

By default, the following builds and installs the faiss-cpu package.

```bash
pip install --no-binary :all: faiss-cpu
```

The following example builds a GPU wheel.

```bash
export FAISS_ENABLE_GPU=ON
pip install --no-binary :all: faiss-cpu
```

There are a few environment variables that specifies build-time options.

- `CUDA_HOME`: Specifies CUDA install location for building faiss-gpu package.
- `FAISS_OPT_LEVEL`: Faiss SIMD optimization, one of `generic`, `avx2`. When set
    to `avx2`, the package internally builds `avx2` extension in addition to
    `generic`. Note this option is only available in x86_64 arch.
- `FAISS_ENABLE_GPU`: Setting this variable to `ON` builds `faiss-gpu` package.
    Set this variable if faiss is built with GPU support.
