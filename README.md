# faiss-wheels 🎡

[![Build](https://github.com/kyamagu/faiss-wheels/actions/workflows/build.yml/badge.svg)](https://github.com/kyamagu/faiss-wheels/actions/workflows/build.yml)
[![PyPI](https://img.shields.io/pypi/v/faiss-cpu?label=faiss-cpu)](https://pypi.org/project/faiss-cpu/)

Faiss Python wheel packages.

- [faiss](https://github.com/facebookresearch/faiss)

## Overview

This repository provides CI scripts to build wheel packages for the
[faiss](https://github.com/facebookresearch/faiss) library.

- Builds wheels with [cibuildwheel](https://github.com/pypa/cibuildwheel/).
- Build backend uses [scikit-build-core](https://github.com/scikit-build/scikit-build-core).
- Default BLAS backend is [OpenBLAS](https://github.com/OpenMathLib/OpenBLAS) on Linux/Windows and [the Accelerate framework](https://developer.apple.com/documentation/accelerate) on macOS.
- Support various build options.

> **Note**
> GPU binary package is discontinued as of 1.7.3 release. Build a custom wheel to support GPU features.

### Install

Install the CPU-only package by:

```bash
pip install faiss-cpu
```

Note that the package name is `faiss-cpu`.

## Building customized wheels

The PyPI binary package does not support GPU by default. To support GPU methods or use faiss with a different build configuration, build a custom wheel. For building a wheel package, there are a few requirements.

- BLAS: There must be a BLAS implementation available on the Linux and Windows platforms.
- OpenMP: macOS requires `libomp` (available via Homebrew).
- CUDA or ROCm: A GPU development toolkit is necessary to support GPU features.

See `scripts/install_*` scripts for details.

### Build instruction

Clone the repository with submodules.

```bash
git clone --recursive https://github.com/kyamagu/faiss-wheels.git
cd faiss-wheels
```

You can use a standard Python environment manager like `pipx` to build a wheel.

```bash
pipx run build --wheel
```

Any build backend supporting `scikit-build-core` can build wheels. For example, you can use `uv` to build wheels.

```bash
uv build --wheel
```

### Build options

You can set environment variables to customize the build options. The following example builds a wheel with AVX2 and CUDA support.

```bash
export FAISS_OPT_LEVELS=avx2
export FAISS_GPU_SUPPORT=CUDA
pipx run build --wheel
```

Alternatively, you may directly pass CMake options via the command line. See [the scikit-build-core documentation](https://scikit-build-core.readthedocs.io/en/latest/configuration/index.html#configuring-cmake-arguments-and-defines) for details on how to specify CMake defines.

```bash
pipx run build --wheel \
    -Ccmake.define.FAISS_OPT_LEVELS=avx2 \
    -Ccmake.define.FAISS_GPU_SUPPORT=CUDA
```

The following options are available for configuration.

- `FAISS_OPT_LEVELS`: Optimization levels. You may set a semicolon-separated list of values from `<generic|avx2|avx512|avx512_spr|sve>`. For example, setting `generic,avx2` will include both `generic` and `avx2` binary extensions in the resulting wheel. This option offers more flexibility than the upstream config variable `FAISS_OPT_LEVEL`, which cannot specify arbitrary combinations.
- `FAISS_GPU_SUPPORT`: GPU support. You may set a value from `<OFF|CUDA|CUVS|ROCM>`. For example, setting `CUDA` will enable CUDA support. For CUDA, you will need the [CUDA toolkit](https://developer.nvidia.com/cuda-toolkit) installed on the system. For ROCm, you will need the [ROCm](https://rocm.docs.amd.com/en/latest/).
- `FAISS_ENABLE_MKL`: Intel MKL support. Default is `OFF`. Setting `FAISS_ENABLE_MKL=ON` links Intel oneAPI Math Kernel Library on Linux. You will need to install [Intel oneAPI MKL](https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl.html) before building a wheel. When `OFF`, the system needs a BLAS backend that CMake can find, such as OpenBLAS.
- `FAISS_USE_LTO`: Enable link time optimization. Default is `ON`. Set `FAISS_USE_LTO=OFF` to disable.

See also the list of supported build-time options in [the upstream documentation](https://github.com/facebookresearch/faiss/blob/main/INSTALL.md#step-1-invoking-cmake). Do not directly set `FAISS_OPT_LEVEL` and `FAISS_ENABLE_GPU` when building a wheel via this project, as that will confuse the build process.

You might want to overwrite the default wheel package name `faiss-cpu` depending on the build option. Manually rewrite the name field in `pyproject.toml` file, or launch the following script to update the project name in `pyproject.toml`.

```bash
./scripts/rename_project.sh faiss-gpu
```

## Development

This repository is intended to support PyPI distribution for the official [faiss](https://github.com/facebookresearch/faiss) library.
The repository contains the CI workflow based on [cibuildwheel](https://github.com/pypa/cibuildwheel/).
Feel free to make a pull request to fix packaging problems.

Currently, GPU wheels result in a large binary size that exceeds the file size limit of PyPI.

Other relevant resources:

- [Packaging projects with GPU code](https://pypackaging-native.github.io/key-issues/gpus/)
