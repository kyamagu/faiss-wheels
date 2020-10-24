# faiss-wheels

![Build and test](https://github.com/kyamagu/faiss-wheels/workflows/Build%20and%20test/badge.svg)
[![PyPI](https://img.shields.io/pypi/v/faiss-cpu?label=faiss-cpu)](https://pypi.org/project/faiss-cpu/)
[![PyPI](https://img.shields.io/pypi/v/faiss-gpu?label=faiss-gpu)](https://pypi.org/project/faiss-gpu/)

faiss python wheel packages.

- [faiss](https://github.com/facebookresearch/faiss)

## Overview

This repository provides scripts to create wheel packages for the
[faiss](https://github.com/facebookresearch/faiss) library.

- Builds CPU-only or CUDA-10.0+ compatible wheels.
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

Or, install CUDA-10.0+ compatible version:

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

The sdist package can be built when faiss is already built and installed.

```bash
cd faiss
cmake -B build . -DFAISS_ENABLE_PYTHON=OFF
make -C build -j8
cd ..
```

Setting `CXXFLAGS="${CXXFLAGS} -avx2 -mf16c"` enables avx2 support in faiss.

See the official
[faiss installation instruction](https://github.com/facebookresearch/faiss/blob/master/INSTALL.md)
for more on how to build and install faiss.

For building sdist, swig 3.0.12 or later needs to be available.

### Linux

By default, the following builds and installs the faiss-cpu package.

```bash
export FAISS_INCLUDE=/usr/local/include
pip install --no-binary :all: faiss-cpu
```

The following example shows static linking and CUDA support:

```bash
export ENABLE_CUDA=true
export FAISS_INCLUDE=/usr/local/include
export FAISS_LDFLAGS='-l:libfaiss.a -l:libopenblas.a -lgfortran -lcudart_static -lcublas_static -lculibos'
pip install --no-binary :all: faiss-gpu
```

There are a few environment variables to specify build-time options.

- `CUDA_HOME`: Specifies CUDA install location.
- `FAISS_INCLUDE`: Header locations of the installed faiss library.
- `FAISS_LDFLAGS`: Linker flags for package build. Default to `-lfaiss`.

The following options are available in the master branch.

- `FAISS_ENABLE_AVX2`: Setting this variable non-empty adds avx2 flags on package
  build.
- `FAISS_ENABLE_GPU`: Setting this variable to `ON` builds `faiss-gpu` package.
  Set this variable if faiss is built with GPU support.

### macOS

On macOS, install `llvm` and `libomp` via Homebrew to build with OpenMP support.
Mac has Accelerate framework for BLAS implementation. Note that compiler flags
can only use absolute path for sdist package. CUDA is not supported on macOS.

```bash
brew install llvm libomp
export CC=/usr/local/opt/llvm/bin/clang
export CXX=/usr/local/opt/llvm/bin/clang++
export FAISS_INCLUDE=/usr/local/include
export FAISS_LDFLAGS='-lfaiss -framework Accelerate'
pip install --no-binary :all: faiss-cpu
```
