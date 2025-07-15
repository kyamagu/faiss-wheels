#!/usr/bin/env bash

set -eux

CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH:-"c:\\opt"}
CMAKE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM:-"x64"}

# Function to install OpenBLAS for Windows ARM64
function install_openblas_arm64() {
    echo "Installing OpenBLAS for Windows ARM64..."
    OPENBLAS_URL="https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.30/OpenBLAS-0.3.30-woa64-dll.zip"
    ZIP_PATH="$RUNNER_TEMP/OpenBLAS.zip"
    DEST_PATH=${CMAKE_PREFIX_PATH}
    curl -sL "$OPENBLAS_URL" -o "$ZIP_PATH"
    mkdir -p "$DEST_PATH"

    # Extract to destination
    powershell.exe -Command "Expand-Archive -Path '$ZIP_PATH' -DestinationPath '$DEST_PATH' -Force"
    powershell.exe -Command "Move-Item $DEST_PATH/OpenBLAS/* $DEST_PATH/ -Force; Remove-Item $DEST_PATH/OpenBLAS -Recurse"
}

# Install system dependencies to build faiss
if [[ "$PROCESSOR_IDENTIFIER" == ARM* ]]; then
    # NOTE: PROCESSOR_ARCHITECTURE is incorrectly set to "AMD64" on emulated ARM64 Windows runners.
    install_openblas_arm64
    CMAKE_GENERATOR_PLATFORM="ARM64"
else
    echo "Installing OpenBLAS for x86_64..."
    conda install -y -c conda-forge openblas
fi

# Build and patch faiss
cd faiss && \
    git apply ../patch/faiss-remove-lapack.patch && \
    cmake . \
        -B build \
        -A ${CMAKE_GENERATOR_PLATFORM} \
        -T ClangCL \
        -DFAISS_ENABLE_GPU=OFF \
        -DFAISS_ENABLE_PYTHON=OFF \
        -DFAISS_OPT_LEVEL=${FAISS_OPT_LEVEL:-"generic"} \
        -DBUILD_TESTING=OFF \
        -DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DBLA_STATIC=ON \
        -DCMAKE_CXX_FLAGS="-D_CRT_SECURE_NO_WARNINGS -Wno-unused-function -Wno-format" && \
    cmake --build build --config Release -j && \
    cmake --install build --prefix "${CMAKE_PREFIX_PATH}" && \
    git apply ../patch/faiss-rename-swigfaiss.patch && \
    cd ..
