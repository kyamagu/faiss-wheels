# BUILD_DEPENDS must happen before our pre_build for Makefile build.
function build_wheel_cmd {
    # Builds wheel with named command, puts into $WHEEL_SDIR
    #
    # Parameters:
    #     cmd  (optional, default "pip_wheel_cmd"
    #        Name of command for building wheel
    #     repo_dir  (optional, default $REPO_DIR)
    #
    # Depends on
    #     REPO_DIR  (or via input argument)
    #     WHEEL_SDIR  (optional, default "wheelhouse")
    #     BUILD_DEPENDS (optional, default "")
    #     MANYLINUX_URL (optional, default "") (via pip_opts function)
    local cmd=${1:-pip_wheel_cmd}
    local repo_dir=${2:-$REPO_DIR}
    [ -z "$repo_dir" ] && echo "repo_dir not defined" && exit 1
    local wheelhouse=$(abspath ${WHEEL_SDIR:-wheelhouse})
    if [ -n "$BUILD_DEPENDS" ]; then
        pip install $(pip_opts) $BUILD_DEPENDS
    fi
    start_spinner
    if [ -n "$(is_function "pre_build")" ]; then pre_build; fi
    stop_spinner
    (cd $repo_dir && $cmd $wheelhouse)
    repair_wheelhouse $wheelhouse
}


function pre_build {
    # Install build dependencies.
    build_swig
    build_openblas

    # Build binary.
    export NUMPY_INCLUDE=$(python -c 'import numpy as np; print(np.get_include())')
    export CFLAGS="-I$NUMPY_INCLUDE $CFLAGS"
    (cd $REPO_DIR/.. \
        && ./configure --without-cuda \
        && make -j4 \
        && make -C python)
}

function run_tests {
    python --version
    python -c 'import faiss'
}
