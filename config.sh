function pre_build {
    # Runs in the root directory.

    # Install newer swig. RPM package is too old.
    yum -y install pcre-devel
    curl -sSLO https://github.com/swig/swig/archive/rel-4.0.0.tar.gz
    tar xzf rel-4.0.0.tar.gz
    cd swig-rel-4.0.0
    ./autogen.sh
    ./configure
    make -j2
    make install
    cd ..

    # Install OpenBLAS.
    yum -y install openblas-devel

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
