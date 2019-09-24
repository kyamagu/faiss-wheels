# Install GCC 4.9 for CUDA 7.5.
function install_devtoolset3 {
    curl -O https://copr.fedorainfracloud.org/coprs/rhscl/devtoolset-3/repo/epel-6/rhscl-devtoolset-3-epel-6.repo \
        && mv rhscl-devtoolset-3-epel-6.repo /etc/yum.repos.d/ \
        && yum install -y \
            devtoolset-3-gcc \
            devtoolset-3-gcc-c++ \
            devtoolset-3-gcc-gfortran \
        && source scl_source enable devtoolset-3 \
        && rm -rf /var/cache/yum/*
}

# Install GCC 5.3.1 for CUDA 8.0+.
function install_devtoolset4 {
    yum install -y yum-utils \
        && yum-config-manager --enable centos-sclo-rh-testing \
        && yum install -y \
            devtoolset-4-gcc \
            devtoolset-4-gcc-c++ \
            devtoolset-4-gcc-gfortran \
        && source scl_source enable devtoolset-4 \
        && rm -rf /var/cache/yum/*
}

# Install GCC 6.2 for CUDA 9.0+.
function install_devtoolset6 {
    yum install -y \
        devtoolset-6-gcc \
        devtoolset-6-gcc-c++ \
        devtoolset-6-gcc-gfortran \
        && source scl_source enable devtoolset-6 \
        && rm -rf /var/cache/yum/*
}

# Check available package versions at
# https://developer.download.nvidia.com/compute/cuda/repos/rhel6/x86_64/
function install_cudart_cublas {
    local cuda_version=${CUDA_VERSION:-7.5}
    local cuda_pkg_version=${CUDA_PKG_VERSION:-7-5-7.5-18}
    local cublas_pkg_version=${CUBLAS_PKG_VERSION:-$cuda_pkg_version}
    NVIDIA_GPGKEY_SUM=d1be581509378368edeec8c1eb2958702feedf3bc3d17011adbf24efacce4ab5
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/rhel6/x86_64/7fa2af80.pub | sed '/^Version/d' > /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA
    echo "$NVIDIA_GPGKEY_SUM  /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA" | sha256sum -c -
    tee /etc/yum.repos.d/cuda.repo <<EOF
[cuda]
name=cuda
baseurl=http://developer.download.nvidia.com/compute/cuda/repos/rhel6/x86_64
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA
EOF
    echo "CUDA_PKG_VERSION=${cuda_pkg_version}"
    echo "CUBLAS_PKG_VERSION=${cublas_pkg_version}"
    yum -y install \
        cuda-command-line-tools-${cuda_pkg_version} \
        cuda-cublas-dev-${cublas_pkg_version}
    rm -rf /var/cache/yum/*
    ln -s cuda-$cuda_version /usr/local/cuda
    echo "/usr/local/cuda/lib64" >> /etc/ld.so.conf.d/cuda.conf
    echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf
    ldconfig
}

function build_faiss {
    aclocal && autoconf
    if [ -n "$IS_OSX" ]; then
        ./configure --without-cuda --with-blas="-framework Accelerate"
    elif [ -n "$CUDA_VERSION" ]; then
        ./configure \
            --with-cuda="/usr/local/cuda" \
            --with-cuda-arch="${CUDA_ARCH_FLAGS:--gencode=arch=compute_35,code=compute_35 -gencode=arch=compute_52,code=compute_52}"
    else
        ./configure --without-cuda
    fi
    cat makefile.inc
    make -j4 && make install
}

function pre_build {
    build_swig > /dev/null
    if [ -n "$IS_OSX" ]; then
        brew install libomp llvm > /dev/null
        local prefix=$(brew --prefix llvm)
        export CC="$prefix/bin/clang"
        export CXX="$prefix/bin/clang++"
        export CXXFLAGS="-stdlib=libc++"
        export CFLAGS="-stdlib=libc++"
        export FAISS_LDFLAGS="/usr/local/lib/libfaiss.a -framework Accelerate"
    else
        echo "Installing openblas"
        if [ "$AUDITWHEEL_PLAT" = "manylinux2010_x86_64" ]; then
            # build_openblas does not work in manylinux2010
            yum install -y openblas-devel openblas-static > /dev/null
        else
            build_openblas > /dev/null
        fi

        export FAISS_LDFLAGS="-l:libfaiss.a -l:libopenblas.a -lgfortran"

        # If CUDA_VERSION is specified, install gcc and cuda toolkit.
        if [ -n "$CUDA_VERSION" ]; then
            echo "Installing devtoolset"
            install_devtoolset${DEVTOOLSET_VERSION} > /dev/null
            echo "Installing cuda libraries"
            install_cudart_cublas > /dev/null
            export FAISS_LDFLAGS="$FAISS_LDFLAGS -lcublas_static -lcudart_static -lculibos"
            export FAISS_BUILD_CUDA=true
        fi
    fi
    (cd $REPO_DIR && build_faiss)
}

function pip_wheel_cmd {
    local abs_wheelhouse=$1
    # Create sdist in one of the linux env.
    if [ ! -n "$IS_OSX" ] && [ "$PYTHON_VERSION" = "3.6" ]; then
        python setup.py sdist --dist-dir $abs_wheelhouse
    fi
    pip wheel $(pip_opts) -w $abs_wheelhouse --no-deps .
}

function run_tests {
    python --version
    python -c "import faiss, numpy; faiss.Kmeans(10, 20).train(numpy.random.rand(1000, 10).astype(numpy.float32))"
}
