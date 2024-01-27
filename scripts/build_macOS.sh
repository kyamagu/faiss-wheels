#!/usr/bin/env bash

FAISS_OPT_LEVEL=${FAISS_OPT_LEVEL:-"generic"}

HOST_ARCH=${HOST_ARCH:-$(uname -m)}
TARGET_ARCH=${TARGET_ARCH:-$HOST_ARCH}
if [[ ${TARGET_ARCH} == auto* || ${TARGET_ARCH} == native ]]; then
    TARGET_ARCH=${HOST_ARCH}
fi
echo "TARGET_ARCH=${TARGET_ARCH}"

# Install system dependencies
brew install swig libomp

# Build and patch faiss
echo "Building faiss"
cd faiss && \
    cmake . \
        -B build \
        -DFAISS_ENABLE_GPU=OFF \
        -DFAISS_ENABLE_PYTHON=OFF \
        -DBUILD_TESTING=OFF \
        -DFAISS_OPT_LEVEL=${FAISS_OPT_LEVEL} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_OSX_ARCHITECTURES=${TARGET_ARCH} && \
    cmake --build build -j && \
    cmake --install build && \
    git apply ../patch/faiss-rename-swigfaiss.patch && \
    cd ..
