#!/usr/bin/env bash

if [ "$CUDA_VERSION" = "7.5" ]; then
    echo export CUDA_VERSION=7.5 >> env_vars.sh
    echo export CUDA_PKG_VERSION=7-5-7.5-18 >> env_vars.sh
elif [ "$CUDA_VERSION" = "8.0" ]; then
    echo export CUDA_VERSION=8.0 >> env_vars.sh
    echo export CUDA_PKG_VERSION=8-0-8.0.61-1 >> env_vars.sh
    echo export CUBLAS_PKG_VERSION=8-0-8.0.61.2-1 >> env_vars.sh
elif [ "$CUDA_VERSION" = "9.0" ]; then
    echo export CUDA_VERSION=9.0 >> env_vars.sh
    echo export CUDA_PKG_VERSION=9-0-9.0.176-1 >> env_vars.sh
    echo export CUBLAS_PKG_VERSION=9-0-9.0.176.4-1 >> env_vars.sh
elif [ "$CUDA_VERSION" = "10.0" ]; then
    echo export CUDA_VERSION=10.0 >> env_vars.sh
    echo export CUDA_PKG_VERSION=10-0-10.0.130-1 >> env_vars.sh
fi
