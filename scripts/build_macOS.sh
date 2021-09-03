#!/usr/bin/env bash

FAISS_OPT_LEVEL=${FAISS_OPT_LEVEL:-"generic"}

# Install system dependencies
brew install libomp swig

# Build and patch faiss
cd faiss && \
    cmake . \
        -B build \
        -DFAISS_ENABLE_GPU=OFF \
        -DFAISS_ENABLE_PYTHON=OFF \
        -DBUILD_TESTING=ON \
        -DFAISS_OPT_LEVEL=${FAISS_OPT_LEVEL} \
        -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build --config Release -j && \
    cmake --install build && \
    mv faiss/python/swigfaiss.swig faiss/python/swigfaiss.i && \
    cd ..
