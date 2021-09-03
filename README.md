# faiss-wheels

[![Build](https://github.com/kyamagu/faiss-wheels/actions/workflows/build.yml/badge.svg)](https://github.com/kyamagu/faiss-wheels/actions/workflows/build.yml)
[![PyPI](https://img.shields.io/pypi/v/faiss-cpu?label=faiss-cpu)](https://pypi.org/project/faiss-cpu/)
[![PyPI](https://img.shields.io/pypi/v/faiss-gpu?label=faiss-gpu)](https://pypi.org/project/faiss-gpu/)

faiss python wheel packages.

- [faiss](https://github.com/facebookresearch/faiss)

## Overview

This repository provides scripts to create wheel packages for the
[faiss](https://github.com/facebookresearch/faiss) library.

- Builds CPU-only or CUDA-10.0+ compatible wheels.
- Bundles OpenBLAS in Linux/Windows
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

Or, install GPU version in Linux:

```bash
pip install faiss-gpu
```

Note that CUDA toolkit is not required to run the GPU wheel. Only NVIDIA drivers
should be installed to use gpu index. One can also install faiss-gpu to run
cpu-only methods without a NVIDIA driver. For compatible NVIDIA driver versions,
check [the developer documentation](https://docs.nvidia.com/deploy/cuda-compatibility/index.html#binary-compatibility__table-toolkit-driver).

## Building source package

If there is a custom built faiss library in the system, build source package for
the best performance.

### Prerequisite

The source package assumes faiss is already built and installed in the system.
Build and install the faiss library first.

```bash
cd faiss
cmake -B build . -DFAISS_ENABLE_PYTHON=OFF
make -C build -j8
make -C build install
cd ..
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

The following example shows static linking and CUDA support:

```bash
export FAISS_ENABLE_GPU=ON
export FAISS_LDFLAGS='-l:libfaiss.a -l:libopenblas.a -lgfortran -lcudart_static -lcublas_static -lculibos'
pip install --no-binary :all: faiss-gpu
```

There are a few environment variables to specify build-time options.

- `CUDA_HOME`: Specifies CUDA install location.
- `FAISS_INCLUDE`: Header locations of the installed faiss library. Default to
    `/usr/local/include`.
- `FAISS_LDFLAGS`: Linker flags for package build. Default to
    `-l:libfaiss.a -l:libopenblas.a -lgfortran`.
- `FAISS_OPT_LEVEL`: Faiss SIMD optimization, one of `generic`, `avx2`.
- `FAISS_ENABLE_GPU`: Setting this variable to `ON` builds `faiss-gpu` package.
    Set this variable if faiss is built with GPU support.

Below is an example for faiss built with `avx2` option and OpenBLAS backend.

```bash
export FAISS_OPT_LEVEL='avx2'
export FAISS_LDFLAGS='-l:libfaiss_avx2.a -l:libopenblas.a -lgfortran'
pip install --no-binary :all: faiss-cpu
```

### macOS

On macOS, install `libomp` via Homebrew to build with OpenMP support. Mac has
Accelerate framework for BLAS implementation. CUDA is not supported on macOS.

```bash
pip install --no-binary :all: faiss-cpu
```

To link to faiss library with `avx2` support, set appropriate environment
variables.

```bash
export FAISS_OPT_LEVEL=avx2
export FAISS_LDFLAGS="/usr/local/lib/libfaiss_avx2.a /usr/local/lib/libomp.a -framework Accelerate"
pip install --no-binary :all: faiss-cpu
```

### Windows

Windows environment requires BLAS/LAPACK and fortran library. See
`.github/workflows/build.yml` for how the binary wheels are built.
