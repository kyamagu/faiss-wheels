#!/usr/bin/env bash

set -eux

export CXXFLAGS="-fvisibility=hidden -fdata-sections -ffunction-sections"

FAISS_ENABLE_GPU=${FAISS_ENABLE_GPU:-"OFF"}

CUDA_VERSION=${CUDA_VERSION:-"12.3"}
CUDA_PKG_VERSION=${CUDA_PKG_VERSION:-${CUDA_VERSION//./-}}
NVIDIA_REPO_URL="http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-rhel7.repo"

# Fix manylinux2014 aarch64
if [[ $(uname -m) == "aarch64" ]]; then
    yum -y install epel-release && yum repolist
fi

# Setup CUDA build environment
if [[ ${FAISS_ENABLE_GPU} == "ON" ]]; then
    echo "Installing CUDA toolkit"
    yum -y install yum-utils && \
        yum-config-manager --add-repo ${NVIDIA_REPO_URL} && \
        yum repolist && \
        yum -y install \
            cuda-compiler-${CUDA_PKG_VERSION} \
            cuda-libraries-devel-${CUDA_PKG_VERSION} \
            cuda-nvprof-${CUDA_PKG_VERSION} \
            devtoolset-7-gcc \
            devtoolset-7-gcc-c++ \
            devtoolset-7-gcc-gfortran \
            devtoolset-7-binutils

    ln -s cuda-${CUDA_VERSION} /usr/local/cuda && \
        echo "/usr/local/cuda/lib64" >> /etc/ld.so.conf.d/cuda.conf && \
        echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
        echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf && \
        ldconfig

    export PATH="/opt/rh/devtoolset-7/root/usr/bin:/usr/local/cuda/bin:${PATH}"
    export CUDAFLAGS="--compiler-options=${CXXFLAGS// /,}"
fi

# Check if swig is available
if ! command -v swig &> /dev/null; then
    echo "swig is not available. Please install swig."
    exit 1
fi
swig -version

# Install system dependencies
yum install -y openblas-devel openblas-static

# Build and patch faiss
cd faiss && \
    cmake . \
        -B build \
        -DFAISS_ENABLE_GPU=${FAISS_ENABLE_GPU} \
        -DFAISS_ENABLE_PYTHON=OFF \
        -DBUILD_TESTING=OFF \
        -DFAISS_OPT_LEVEL=${FAISS_OPT_LEVEL:-"generic"} \
        -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build --config Release -j3 && \
    cmake --install build && \
    git apply ../patch/faiss-rename-swigfaiss.patch && \
    cd ..
