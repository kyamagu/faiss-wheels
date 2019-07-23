#!/usr/bin/env bash

if [ "$CUDA_VERSION" = "7.5" ]; then
    # Maxwell
    echo export CUDA_VERSION=7.5 >> env_vars.sh
    echo export CUDA_PKG_VERSION=7-5-7.5-18 >> env_vars.sh
    echo export CUDA_ARCH_FLAGS="-gencode=arch=compute_35,code=sm_35 -gencode=arch=compute_52,code=sm_52 -gencode=arch=compute_52,code=compute_52" >> env_vars.sh
elif [ "$CUDA_VERSION" = "8.0" ]; then
    # Pascal
    echo export CUDA_VERSION=8.0 >> env_vars.sh
    echo export CUDA_PKG_VERSION=8-0-8.0.61-1 >> env_vars.sh
    echo export CUBLAS_PKG_VERSION=8-0-8.0.61.2-1 >> env_vars.sh
    echo export CUDA_ARCH_FLAGS="-gencode=arch=compute_35,code=sm_35 -gencode=arch=compute_52,code=sm_52 -gencode=arch=compute_60,code=sm_60 -gencode=arch=compute_61,code=sm_61 -gencode=arch=compute_61,code=compute_61" >> env_vars.sh
elif [ "$CUDA_VERSION" = "9.0" ]; then
    # Volta
    echo export CUDA_VERSION=9.0 >> env_vars.sh
    echo export CUDA_PKG_VERSION=9-0-9.0.176-1 >> env_vars.sh
    echo export CUBLAS_PKG_VERSION=9-0-9.0.176.4-1 >> env_vars.sh
    echo export CUDA_ARCH_FLAGS="-gencode=arch=compute_52,code=sm_52 -gencode=arch=compute_60,code=sm_60 -gencode=arch=compute_61,code=sm_61 -gencode=arch=compute_70,code=sm_70 -gencode=arch=compute_70,code=compute_70" >> env_vars.sh
elif [ "$CUDA_VERSION" = "10.0" ]; then
    # Turing
    echo export CUDA_VERSION=10.0 >> env_vars.sh
    echo export CUDA_PKG_VERSION=10-0-10.0.130-1 >> env_vars.sh
    echo export CUDA_ARCH_FLAGS="-gencode=arch=compute_52,code=sm_52 -gencode=arch=compute_60,code=sm_60 -gencode=arch=compute_61,code=sm_61 -gencode=arch=compute_70,code=sm_70 -gencode=arch=compute_75,code=sm_75 -gencode=arch=compute_75,code=compute_75" >> env_vars.sh
fi
