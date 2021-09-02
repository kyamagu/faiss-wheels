#!/usr/bin/env bash

CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH:-"c:\\opt"}
FAISS_OPT_LEVEL=${FAISS_OPT_LEVEL:-"generic"}

export PATH="C:\\Miniconda\\condabin:${PATH}"
export LIB="${LIB};${CONDA_PREFIX}\\Library\\lib;${CMAKE_PREFIX_PATH}\\lib"
export CPATH="${CPATH};${CONDA_PREFIX}\\Library\\include;${CMAKE_PREFIX_PATH}\\include"

# Install system dependencies
echo $PATH
conda config --add channels conda-forge
conda install -y swig openblas

# Build and patch faiss

cd faiss && \
    git apply ../patch/faiss-remove-lapack.patch && \
    cmake . \
        -B build \
        -A x64 \
        -DFAISS_ENABLE_GPU=OFF \
        -DFAISS_ENABLE_PYTHON=OFF \
        -DFAISS_OPT_LEVEL=${FAISS_OPT_LEVEL} \
        -DBUILD_TESTING=ON \
        -DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}" \
        -DBLA_VENDOR=OpenBLAS \
        -DBLA_STATIC=ON && \
    cmake --build build --config Release -j -v && \
    cmake --install build --prefix ${CMAKE_PREFIX_PATH} -v && \
    mv faiss/python/swigfaiss.swig faiss/python/swigfaiss.i && \
    cd ..
