function pre_build {
    # Runs in the root directory.
    yum -y install swig
    cd $REPO_DIR
    autoconf
    ./configure --without-cuda
    make -j2
}

function run_tests {
    python --version
}
