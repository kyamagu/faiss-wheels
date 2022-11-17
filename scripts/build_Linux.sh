#!/usr/bin/env bash

export CXXFLAGS="-fvisibility=hidden -fdata-sections -ffunction-sections"

FAISS_ENABLE_GPU=${FAISS_ENABLE_GPU:-"OFF"}
FAISS_OPT_LEVEL=${FAISS_OPT_LEVEL:-"generic"}

CUDA_VERSION="11.0"
CUDA_PKG_VERSION="11-0"
NVIDIA_REPO_URL="http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-rhel7.repo"
CMAKE_CUDA_ARCHITECTURES="60-real;70-real;75-real;80"

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
    export CUDAFLAGS="--compiler-options=-fvisibility=hidden,-fdata-sections,-ffunction-sections"
fi

# Install system dependencies
yum install -y \
    openblas-devel \
    openblas-static \
    swig3

# Build and patch faiss
cd faiss && \
    cmake . \
        -B build \
        -DFAISS_ENABLE_GPU=${FAISS_ENABLE_GPU} \
        -DFAISS_ENABLE_PYTHON=OFF \
        -DBUILD_TESTING=OFF \
        -DCMAKE_CUDA_ARCHITECTURES=${CMAKE_CUDA_ARCHITECTURES} \
        -DFAISS_OPT_LEVEL=${FAISS_OPT_LEVEL} \
        -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build --config Release -j3 && \
    cmake --install build && \
    git apply ../patch/faiss-rename-swigfaiss.patch && \
    cd ..
