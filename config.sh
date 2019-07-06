function build_faiss {
    if [ -n "$IS_OSX" ]; then
        local extra_args="--with-blas='-framework Accelerate'"
    else
        local extra_args=""
    fi
    (aclocal \
        && autoconf \
        && ./configure --without-cuda $extra_args \
        && make -j4 \
        && make install)
}

function pre_build {
    build_swig > /dev/null
    if [ -n "$IS_OSX" ]; then
        brew install libomp llvm > /dev/null
        local prefix=$(brew --prefix llvm)
        export CC="$prefix/bin/clang"
        export CXX="$prefix/bin/clang++"
    else
        build_openblas > /dev/null
    fi
    (cd $REPO_DIR && build_faiss)
}

function pip_wheel_cmd {
    local abs_wheelhouse=$1
    if [ ! -n "$IS_OSX" ]; then
        export BLAS_LIB="-pthread /usr/lib/libopenblas.a -lgfortran"
    fi
    pip wheel $(pip_opts) -w $abs_wheelhouse --no-deps . \
        --include-dirs=/usr/local/include/faiss
}

function run_tests {
    if [ ! -n "$IS_OSX" ]; then
        apt-get update \
            && apt-get install -y libopenblas-base \
            && rm -rf /var/lib/apt/lists/*
    fi
    python --version
    python -c "import faiss, numpy; faiss.Kmeans(10, 20).train(numpy.random.rand(1000, 10).astype(numpy.float32))"
}
