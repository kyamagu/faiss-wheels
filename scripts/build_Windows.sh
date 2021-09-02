#!/usr/bin/env bash

CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH:-"c:\\opt"}
FAISS_OPT_LEVEL=${FAISS_OPT_LEVEL:-"generic"}
VCPKG_INSTALLATION_ROOT=${VCPKG_INSTALLATION_ROOT:-"C:\\vcpkg"}

# Install system dependencies
vcpkg install lapack:x64-windows openblas:x64-windows

# Build and patch faiss
cd faiss && \
    cmake . \
        -B build \
        -A x64 \
        -DFAISS_ENABLE_GPU=OFF \
        -DFAISS_ENABLE_PYTHON=OFF \
        -DFAISS_OPT_LEVEL=${FAISS_OPT_LEVEL} \
        -DBUILD_TESTING=OFF \
        -DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}" \
        -DCMAKE_TOOLCHAIN_FILE="${VCPKG_INSTALLATION_ROOT}\\scripts\\buildsystems\\vcpkg.cmake" \
        -DCMAKE_BUILD_TYPE=Release \
        -DBLA_STATIC=ON && \
    cmake --build build --config Release -j && \
    cmake --install build --prefix ${CMAKE_PREFIX_PATH} && \
    mv faiss/python/swigfaiss.swig faiss/python/swigfaiss.i && \
    cd ..
