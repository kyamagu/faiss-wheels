#!/usr/bin/env bash

set -eux

CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH:-"c:\\opt"}

# Install system dependencies
vcpkg install openblas

# Build and patch faiss
cd faiss && \
    git apply ../patch/faiss-remove-lapack.patch && \
    cmake . \
        -B build \
        -T ClangCL \
        -DFAISS_ENABLE_GPU=OFF \
        -DFAISS_ENABLE_PYTHON=OFF \
        -DFAISS_OPT_LEVEL=${FAISS_OPT_LEVEL:-"generic"} \
        -DBUILD_TESTING=OFF \
        -DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DBLA_STATIC=ON \
        -DCMAKE_CXX_FLAGS="-D_CRT_SECURE_NO_WARNINGS -Wno-unused-function -Wno-format" && \
    cmake --build build --config Release -j && \
    cmake --install build --prefix "${CMAKE_PREFIX_PATH}" && \
    git apply ../patch/faiss-rename-swigfaiss.patch && \
    cd ..
