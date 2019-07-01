function pre_build {
    # Install build dependencies.
    build_swig
    build_openblas

    # Build binary.
    cd $REPO_DIR/..
    ./configure --without-cuda
    make -j2
    make -C python
    cd ..
}

function run_tests {
    python --version
}
