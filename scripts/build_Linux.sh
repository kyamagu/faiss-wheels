#!/usr/bin/env bash

set -eux

# Default compiler flags
export CXXFLAGS=${CXXFLAGS:-"-fvisibility=hidden -fdata-sections -ffunction-sections"}

# Install system dependencies
if command -v apk &> /dev/null; then
    apk add --no-cache openblas-dev swig
elif command -v dnf &> /dev/null; then
    dnf install -y openblas-devel openblas-static swig
elif command -v apt &> /dev/null; then
    apt install -y libopenblas-dev swig
elif command -v yum &> /dev/null; then
    yum install -y openblas-devel openblas-static swig
else
    echo "Unsupported package manager. Please install dependencies manually."
    exit 1
fi
swig -version

# Build and patch faiss
cd third-party/faiss && \
    cmake . \
        -B build \
        -DFAISS_ENABLE_GPU=${FAISS_ENABLE_GPU:-"OFF"} \
        -DFAISS_ENABLE_PYTHON=OFF \
        -DBUILD_TESTING=OFF \
        -DFAISS_OPT_LEVEL=${FAISS_OPT_LEVEL:-"generic"} \
        -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build --config Release -j3 && \
    cmake --install build && \
    git apply ../../patch/faiss-rename-swigfaiss.patch && \
    cd ../..
