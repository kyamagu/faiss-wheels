# faiss-wheels

[![Travis-CI](https://img.shields.io/travis/kyamagu/faiss-wheels.svg)](https://travis-ci.org/kyamagu/faiss-wheels)

Unofficial faiss builder based on multibuild.

- [faiss](https://github.com/facebookresearch/faiss)
- [multibuild](https://github.com/matthew-brett/multibuild)

## Overview

This repository provides pre-built wheel packages for
[faiss](https://github.com/facebookresearch/faiss) library.

The packages are uploaded to https://storage.cloud.google.com/ailab-wheels/

- CPU-only builds
- Bundles OpenBLAS in Linux using static linking and `auditwheel`
- Uses Accelerate framework on macOS

## Building source package

### Prerequisite

The sdist package can be built when faiss is already built and installed.

```bash
cd faiss
aclocal \
    && autoconf \
    && ./configure --without-cuda \
    && make -j4 \
    && make install
```

See the official
[faiss installation instruction](https://github.com/facebookresearch/faiss/blob/master/INSTALL.md)
for more on how to build and install faiss.

For building sdist, `swig` needs to be available.

### Linux

Once faiss is installed, header locations and link flags can be specified by
`FAISS_INCLUDE` and `FAISS_LDFLAGS` environment variables for building sdist:

```bash
export FAISS_INCLUDE=/usr/local/include/faiss
export FAISS_LDFLAGS='-lfaiss -L/usr/local/lib'
pip install faiss-cpu-1.5.3.tar.gz
```

It is also possible to statically link dependent libraries:

```bash
export FAISS_LDFLAGS='-l:libfaiss.a -l:libopenblas.a -lgfortran'
pip install faiss-cpu-1.5.3.tar.gz
```

### macOS

On macOS, install `llvm` and `libomp` via Homebrew to build with OpenMP support.
Mac has Accelerate framework for BLAS implementation. Note that compiler flags
can only use absolute path for sdist package.

```bash
brew install llvm libomp
export CC=/usr/local/opt/llvm/bin/clang
export CXX=/usr/local/opt/llvm/bin/clang++
export FAISS_INCLUDE=/usr/local/include/faiss
export FAISS_LDFLAGS='-lfaiss -framework Accelerate'
pip install faiss-cpu-1.5.3.tar.gz
```
