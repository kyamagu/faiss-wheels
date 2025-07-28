#!/usr/bin/env bash

set -eux

CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH:-"c:\\opt"}

# Function to install OpenBLAS for Windows
function install_openblas() {
    echo "Installing OpenBLAS for Windows..."
    local OPENBLAS_URL="https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.30/OpenBLAS-0.3.30-$1.zip"
    local ZIP_PATH="$RUNNER_TEMP/OpenBLAS.zip"
    local DEST_PATH=${CMAKE_PREFIX_PATH}
    curl -sL "$OPENBLAS_URL" -o "$ZIP_PATH"
    mkdir -p "$DEST_PATH"

    # Extract to destination
    powershell.exe -Command "Expand-Archive -Path '$ZIP_PATH' -DestinationPath '$DEST_PATH' -Force"
    powershell.exe -Command "Move-Item $DEST_PATH/OpenBLAS*/* $DEST_PATH/ -Force; Remove-Item $DEST_PATH/OpenBLAS* -Recurse"
}

# Install system dependencies to build faiss
if [[ "$PROCESSOR_IDENTIFIER" == ARM* ]]; then
    # NOTE: PROCESSOR_ARCHITECTURE is incorrectly set to "AMD64" on emulated ARM64 Windows runners.
    install_openblas woa64-dll
    CMAKE_GENERATOR_PLATFORM="ARM64"
else
    install_openblas x64
    powershell.exe -Command "New-Item -Path $DEST_PATH/lib/openblas.lib -ItemType SymbolicLink -Target $DEST_PATH/lib/libopenblas.lib"
    CMAKE_GENERATOR_PLATFORM="x64"
fi

# Build and patch faiss
cd third-party/faiss && \
    git apply ../../patch/faiss-remove-lapack.patch && \
    git apply ../../patch/faiss-fix-omp-loop-signed-index.patch && \
    cmake . \
        -B build \
        -A $CMAKE_GENERATOR_PLATFORM \
        -T v143 \
        -DFAISS_ENABLE_GPU=OFF \
        -DFAISS_ENABLE_PYTHON=OFF \
        -DFAISS_OPT_LEVEL=${FAISS_OPT_LEVEL:-"generic"} \
        -DBUILD_TESTING=OFF \
        -DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DBLA_STATIC=ON && \
    cmake --build build --config Release -j && \
    cmake --install build --prefix "${CMAKE_PREFIX_PATH}" && \
    git apply ../../patch/faiss-rename-swigfaiss.patch && \
    cd ../..
