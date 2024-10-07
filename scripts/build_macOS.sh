#!/usr/bin/env bash

set -eux

HOST_ARCH=${HOST_ARCH:-$(uname -m)}
TARGET_ARCH=${TARGET_ARCH:-$HOST_ARCH}
if [[ ${TARGET_ARCH} == auto* || ${TARGET_ARCH} == native ]]; then
    TARGET_ARCH=${HOST_ARCH}
fi
echo "TARGET_ARCH=${TARGET_ARCH}"

# Fix directory structure
sudo mkdir -p /usr/local/include && \
    sudo chown -R $(whoami) /usr/local/include
sudo mkdir -p /usr/local/lib && \
    sudo chown -R $(whoami) /usr/local/lib
sudo mkdir -p /usr/local/share && \
    sudo chown -R $(whoami) /usr/local/share

# Install system dependencies
brew install swig libomp

# Build libomp: needed for cross compilation
function build_libomp() {
    echo "Building libomp"
    git clone \
            --depth 1 \
            --filter=blob:none \
            --sparse \
            --branch ${LLVM_VERSION:-"llvmorg-17.0.6"} \
            https://github.com/llvm/llvm-project.git \
            third-party/llvm-project && \
        cd third-party/llvm-project && \
        git sparse-checkout set openmp cmake && \
        cd openmp && \
        cmake . \
            -B build \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_OSX_ARCHITECTURES=${TARGET_ARCH} \
            -DLIBOMP_ENABLE_SHARED=ON && \
        cmake --build build -j && \
        cmake --install build && \
        cd ../../..
}

# Build and patch faiss
echo "Building faiss"
cd faiss && \
    cmake . \
        -B build \
        -DFAISS_ENABLE_GPU=OFF \
        -DFAISS_ENABLE_PYTHON=OFF \
        -DBUILD_TESTING=OFF \
        -DFAISS_OPT_LEVEL=${FAISS_OPT_LEVEL:-"generic"} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_OSX_ARCHITECTURES=${TARGET_ARCH} && \
    cmake --build build --config Release -j && \
    cmake --install build && \
    git apply ../patch/faiss-rename-swigfaiss.patch && \
    cd ..
