#!/usr/bin/env bash

FAISS_OPT_LEVEL=${FAISS_OPT_LEVEL:-"generic"}

HOST_ARCH=${HOST_ARCH:-$(uname -m)}
TARGET_ARCH=${TARGET_ARCH:-$HOST_ARCH}
if [[ ${TARGET_ARCH} == auto* || ${TARGET_ARCH} == native ]]; then
    TARGET_ARCH=${HOST_ARCH}
fi
echo "TARGET_ARCH=${TARGET_ARCH}"

# Install system dependencies
brew install swig

if [[ ${TARGET_ARCH} == ${HOST_ARCH} ]]; then
    brew install libomp
else
    echo "Building libomp (${TARGET_ARCH})"
    git clone \
            --depth 1 \
            --filter=blob:none \
            --sparse \
            https://github.com/llvm/llvm-project.git && \
        cd llvm-project && \
        git sparse-checkout set openmp && \
        cd openmp && \
        cmake . \
            -B build \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_OSX_ARCHITECTURES=${TARGET_ARCH} && \
        cmake --build build -j && \
        cmake --install build && \
        cd ../..
fi

# Build and patch faiss
cd faiss && \
    cmake . \
        -B build \
        -DFAISS_ENABLE_GPU=OFF \
        -DFAISS_ENABLE_PYTHON=OFF \
        -DBUILD_TESTING=OFF \
        -DFAISS_OPT_LEVEL=${FAISS_OPT_LEVEL} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_OSX_ARCHITECTURES=${TARGET_ARCH} && \
    cmake --build build --config Release -j -v && \
    cmake --install build && \
    mv faiss/python/swigfaiss.swig faiss/python/swigfaiss.i && \
    cd ..
