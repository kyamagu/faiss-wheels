#!/usr/bin/env bash

set -eux

# Default compiler flags
export CXXFLAGS=${CXXFLAGS:-"-fvisibility=hidden -fdata-sections -ffunction-sections"}

# Check if swig is available
if ! command -v swig &> /dev/null; then
    echo "swig is not available. Please install swig."
    exit 1
fi
swig -version

# Install system dependencies
dnf install -y openblas-devel openblas-static

# Build and patch faiss
cd faiss && \
    cmake . \
        -B build \
        -DFAISS_ENABLE_GPU=${FAISS_ENABLE_GPU:-"OFF"} \
        -DFAISS_ENABLE_PYTHON=OFF \
        -DBUILD_TESTING=OFF \
        -DFAISS_OPT_LEVEL=${FAISS_OPT_LEVEL:-"generic"} \
        -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build --config Release -j3 && \
    cmake --install build && \
    git apply ../patch/faiss-rename-swigfaiss.patch && \
    cd ..
