#!/usr/bin/env bash
set -eux

# Install OpenBLAS for Windows ARM64
echo "Installing OpenBLAS for Windows ARM64..."
url="https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.30/OpenBLAS-0.3.30-woa64-dll.zip"
zipPath="$RUNNER_TEMP/OpenBLAS.zip"
destPath="C:/opt"

# Download OpenBLAS
curl -L "$url" -o "$zipPath"
# Create destination directory
mkdir -p "$destPath"
# Extract OpenBLAS
powershell.exe -Command "Expand-Archive -Path '$zipPath' -DestinationPath '$destPath' -Force"

# Set CMAKE_PREFIX_PATH
CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH:-"c:\\opt"}

# Build and patch faiss
cd faiss && \
git apply ../patch/faiss-remove-lapack.patch && \
cmake . -B build -A ARM64 \
    -DFAISS_ENABLE_GPU=OFF \
    -DFAISS_ENABLE_PYTHON=OFF \
    -DFAISS_OPT_LEVEL=${FAISS_OPT_LEVEL:-"generic"} \
    -DBUILD_TESTING=OFF \
    -DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBLA_STATIC=ON && \
cmake --build build --config Release -j && \
cmake --install build --prefix "${CMAKE_PREFIX_PATH}" && \
git apply ../patch/faiss-rename-swigfaiss.patch && \
cd ..
