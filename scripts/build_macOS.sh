#!/usr/bin/env bash

set -eux

# Fix directory structure on homebrew for intel macOS
for dir in "include" "lib" "share"; do
    sudo mkdir -p "/usr/local/$dir"
    sudo chown -R $(whoami) "/usr/local/$dir"
done

# Install system dependencies
brew install swig libomp

# Workaround for libomp
export OpenMP_ROOT=$(brew --prefix)/opt/libomp

# Build and patch faiss
echo "Building faiss"
cd third-party/faiss && \
    cmake . \
        -B build \
        -DFAISS_ENABLE_GPU=OFF \
        -DFAISS_ENABLE_PYTHON=OFF \
        -DBUILD_TESTING=OFF \
        -DFAISS_OPT_LEVEL=${FAISS_OPT_LEVEL:-"generic"} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_FLAGS="-Wno-deprecated-declarations -Wno-format" && \
    cmake --build build --config Release -j && \
    cmake --install build && \
    git apply ../../patch/faiss-rename-swigfaiss.patch && \
    cd ../..
