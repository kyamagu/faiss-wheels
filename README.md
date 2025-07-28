# faiss-wheels

[![Build](https://github.com/kyamagu/faiss-wheels/actions/workflows/build.yml/badge.svg)](https://github.com/kyamagu/faiss-wheels/actions/workflows/build.yml)
[![PyPI](https://img.shields.io/pypi/v/faiss-cpu?label=faiss-cpu)](https://pypi.org/project/faiss-cpu/)

faiss python wheel packages.

- [faiss](https://github.com/facebookresearch/faiss)

## Overview

This repository provides scripts to build wheel packages for the
[faiss](https://github.com/facebookresearch/faiss) library.

- Builds CPU-only version with [cibuildwheel](https://github.com/pypa/cibuildwheel/).
- Bundles [OpenBLAS](https://github.com/OpenMathLib/OpenBLAS) in Linux/Windows
- Uses Accelerate framework in macOS

There is also a source package to customize the build process.

> **Note**
> GPU binary package is discontinued as of 1.7.3 release. Build a source package to support GPU features.

### Install

Install the CPU-only binary package by:

```bash
pip install faiss-cpu
```

Note that the package name is `faiss-cpu`.

## Supporting GPU or customized build configuration

The PyPI binary package does not support GPU.
To support GPU methods or use faiss with different build configuration, build a source package.
For building the source package, swig 3.0.12 or later needs to be available.
Also, there should be all the required prerequisites for building faiss itself, such as `nvcc` and CUDA toolkit.

## Building faiss

*The source package assumes faiss and OpenBLAS are already built and installed in the system.*
If not done so elsewhere, build and install the faiss library first.
The following example builds and installs faiss with GPU support and avx512 instruction set.

```bash
git clone https://github.com/facebookresearch/faiss.git
cd faiss
cmake . -B build -DFAISS_ENABLE_GPU=ON -DFAISS_ENABLE_PYTHON=OFF -DFAISS_OPT_LEVEL=avx512
cmake --build build --config Release -j
cmake --install build install
cd ..
```

See the official
[faiss installation instruction](https://github.com/facebookresearch/faiss/blob/master/INSTALL.md)
for more on how to build and install faiss.

### Building and installing a source package

Once faiss is built and installed, build the source package.
The following builds and installs the faiss-cpu source package with GPU and AVX512.

```bash
export FAISS_ENABLE_GPU=ON FAISS_OPT_LEVEL=avx512
pip install --no-binary :all: faiss-cpu
```

There are a few environment variables that specifies build-time options.
- `FAISS_INSTALL_PREFIX`: Specifies the install location of faiss library, default to `/usr/local`.
- `FAISS_OPT_LEVEL`: Faiss SIMD optimization, one of `generic`, `avx2`, `avx512`. Note that AVX option is only available in x86_64 arch.
- `FAISS_ENABLE_GPU`: Setting this variable to `ON` builds GPU wrappers. Set this variable if faiss is built with GPU support.
- `CUDA_HOME`: Specifies CUDA install location for building GPU wrappers, default to `/usr/local/cuda`.

Note that you can build a custom wheel package without installing it. The resulting package can be installed in the other python environment as long as the ABI is the same. Otherwise, use [`auditwheel`](https://github.com/pypa/auditwheel) or similar tools to package the binary dependency after building a wheel.

```bash
export FAISS_ENABLE_GPU=ON FAISS_OPT_LEVEL=avx512
pip wheel --no-binary :all: faiss-cpu
```

> **Note**
> Currently, the source package only supports the OpenBLAS backend; other BLAS implementation is not supported.

## Development

This repository is intended to support PyPI distribution for the official [faiss](https://github.com/facebookresearch/faiss) library.
The repository contains the CI workflow based on [cibuildwheel](https://github.com/pypa/cibuildwheel/).
Feel free to make a pull request to fix packaging problems.

Other relevant resources:

- [Packaging projects with GPU code](https://pypackaging-native.github.io/key-issues/gpus/)