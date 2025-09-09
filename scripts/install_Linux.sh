#!/usr/bin/env bash

set -eux

FAISS_GPU_SUPPORT=${FAISS_GPU_SUPPORT:-OFF}
FAISS_ENABLE_MKL=${FAISS_ENABLE_MKL:-OFF}

# OpenBLAS installation
function install_openblas() {
    if command -v apk &> /dev/null; then
        apk add --no-cache openblas-dev
    elif command -v dnf &> /dev/null; then
        dnf install -y openblas-devel
    elif command -v apt &> /dev/null; then
        apt install -y libopenblas-dev
    elif command -v yum &> /dev/null; then
        yum install -y openblas-devel
    else
        echo "Unsupported package manager. Please install OpenBLAS manually."
    fi
}

# Intel MKL installation
function install_intel_mkl() {
    if command -v apk &> /dev/null; then
        echo "Intel MKL installation on Alpine is not supported yet."
    elif command -v dnf &> /dev/null; then
        tee /etc/yum.repos.d/oneAPI.repo << EOF
[oneAPI]
name=Intel® oneAPI repository
baseurl=https://yum.repos.intel.com/oneapi
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
EOF
        dnf install -y intel-oneapi-mkl-devel
        tee /etc/ld.so.conf.d/oneapi.conf <<EOF
/opt/intel/oneapi/mkl/latest/lib
/opt/intel/oneapi/compiler/latest/lib/
EOF
        ldconfig
    elif command -v apt &> /dev/null; then
        wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
            | gpg --dearmor \
            | tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null
        echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" \
            | tee /etc/apt/sources.list.d/oneAPI.list
        apt update && apt install -y intel-oneapi-mkl-devel
        tee /etc/ld.so.conf.d/oneapi.conf <<EOF
/opt/intel/oneapi/mkl/latest/lib
/opt/intel/oneapi/compiler/latest/lib/
EOF
        ldconfig
    else
        echo "Unsupported package manager. Please install Intel MKL manually."
    fi
}

# CUDA installation
function install_cuda() {
    local ARCH=$(uname -m)
    local CUDA_VERSION=${CUDA_VERSION:-12.8}
    local CUDA_PACKAGE_VERSION=${CUDA_VERSION//./-}
    if command -v apk &> /dev/null; then
        echo "CUDA installation on Alpine is not supported yet."
        exit 1
    elif command -v dnf &> /dev/null; then
        # TODO: Detect DISTRO via /etc/*-release.
        local DISTRO=${DISTRO:-rhel8}
        dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/${ARCH}/cuda-${DISTRO}.repo
        dnf install -y \
            cuda-nvcc-${CUDA_PACKAGE_VERSION} \
            cuda-profiler-api-${CUDA_PACKAGE_VERSION} \
            cuda-cudart-devel-${CUDA_PACKAGE_VERSION} \
            libcublas-devel-${CUDA_PACKAGE_VERSION} \
            libcurand-devel-${CUDA_PACKAGE_VERSION}
    elif command -v apt &> /dev/null; then
        local DISTRO=${DISTRO:-ubuntu2404}
        wget https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/${ARCH}/cuda-keyring_1.1-1_all.deb
        dpkg -i cuda-keyring_1.1-1_all.deb
        apt update && apt install -y \
            cuda-nvcc-${CUDA_PACKAGE_VERSION} \
            cuda-profiler-api-${CUDA_PACKAGE_VERSION} \
            cuda-cudart-dev-${CUDA_PACKAGE_VERSION} \
            libcublas-dev-${CUDA_PACKAGE_VERSION} \
            libcurand-dev-${CUDA_PACKAGE_VERSION}
    else
        echo "Unsupported package manager. Please install CUDA Toolkit manually."
    fi
}

# ROCm installation
function install_rocm() {
    local ROCM_VERSION=${ROCM_VERSION:-6.4.3}
    if command -v apk &> /dev/null; then
        echo "ROCm installation on Alpine is not supported yet."
        exit 1
    elif command -v dnf &> /dev/null; then
        local DISTRO=${DISTRO:-el8}
        tee /etc/yum.repos.d/rocm.repo <<EOF
[ROCm-${ROCM_VERSION}]
name=ROCm${ROCM_VERSION}
baseurl=https://repo.radeon.com/rocm/${DISTRO}/${ROCM_VERSION}/main
enabled=1
priority=50
gpgcheck=1
gpgkey=https://repo.radeon.com/rocm/rocm.gpg.key
EOF
        dnf install -y \
            rocm-llvm \
            rocm-hip-runtime-devel \
            hipblas-devel \
            hiprand-devel \
            rocrand-devel \
            rocthrust-devel
        ln -s libstdc++.so.6 /usr/lib64/libstdc++.so
        echo "/opt/rocm/lib" > /etc/ld.so.conf.d/rocm.conf && ldconfig
    elif command -v apt &> /dev/null; then
        local DISTRO=${DISTRO:-noble}
        wget https://repo.radeon.com/rocm/rocm.gpg.key -O - \
            | gpg --dearmor \
            | tee /etc/apt/keyrings/rocm.gpg > /dev/null
        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/${ROCM_VERSION} ${DISTRO} main" \
            | tee /etc/apt/sources.list.d/rocm.list
        echo -e 'Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600' \
            | tee /etc/apt/preferences.d/rocm-pin-600
        apt update && apt install -y \
            rocm-llvm \
            rocm-hip-runtime-devel \
            hipblas-devel \
            hiprand-devel \
            rocrand-devel \
            rocthrust-devel
        echo "/opt/rocm/lib" > /etc/ld.so.conf.d/rocm.conf && ldconfig
    else
        echo "Unsupported package manager. Please install ROCm manually."
    fi
}

# Main script execution
if [ "${FAISS_ENABLE_MKL^^}" = "ON" ]; then
    install_intel_mkl
else
    install_openblas
fi

if [ "${FAISS_GPU_SUPPORT^^}" = "CUDA" ] || [ "${FAISS_GPU_SUPPORT^^}" = "CUVS" ]; then
    install_cuda
elif [ "${FAISS_GPU_SUPPORT^^}" = "ROCM" ]; then
    install_rocm
fi