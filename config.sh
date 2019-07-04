function build_faiss {
    echo $PWD
    if [ -n "$IS_OSX" ]; then
        local with_blas="-framework Accelerate"
    else
        local with_blas="-pthread -lgfortran -static-libgfortran -l:libopenblas.a"
    fi
    (aclocal \
        && autoconf \
        && ./configure --without-cuda --with-blas="$with_blas" \
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

function run_tests {
    if [ ! -n "$IS_OSX" ]; then
        apt-get update \
            && apt-get install -y libgfortran3 \
            && rm -rf /var/lib/apt/lists/*
    fi
    python --version
    python -c "import faiss, numpy; faiss.Kmeans(10, 20).train(numpy.random.rand(1000, 10).astype('float32'))"
}
