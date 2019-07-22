function install_cuda_repo {
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
}

function install_cuda_libs {
    local cuda_version=${CUDA_VERSION:-7.5}
    local cuda_pkg_version=${CUDA_PKG_VERSION:-7-5-7.5-18}
    yum -y install \
        cuda-command-line-tools-$cuda_pkg_version \
        cuda-cublas-dev-$cuda_pkg_version \
        cuda-cudart-dev-$cuda_pkg_version \
        && rm -rf /var/cache/yum/* \
        && ln -s cuda-$cuda_version /usr/local/cuda \
        && echo "/usr/local/cuda/lib64" >> /etc/ld.so.conf.d/cuda.conf \
        && echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf \
        && echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf \
        && ldconfig
}

function install_devtoolset3 {
    curl -O https://copr.fedorainfracloud.org/coprs/rhscl/devtoolset-3/repo/epel-6/rhscl-devtoolset-3-epel-6.repo \
        && mv rhscl-devtoolset-3-epel-6.repo /etc/yum.repos.d/ \
        && yum remove -y devtoolset-8* > /dev/null \
        && yum install -y \
            devtoolset-3-gcc \
            devtoolset-3-gcc-c++ \
        && rm -rf /var/cache/yum/*
    export PATH=/opt/rh/devtoolset-3/root/usr/bin:$PATH
    export LD_LIBRARY_PATH=/opt/rh/devtoolset-3/root/usr/lib64:/opt/rh/devtoolset-3/root/usr/lib:/opt/rh/devtoolset-3/root/usr/lib64/dyninst:/opt/rh/devtoolset-3/root/usr/lib/dyninst:/usr/local/lib64:/usr/local/lib
}

function build_faiss {
    aclocal && autoconf
    if [ -n "$IS_OSX" ]; then
        ./configure --without-cuda --with-blas="-framework Accelerate"
    else
        ./configure \
            --with-cuda="/usr/local/cuda" \
            --with-cuda-arch="-gencode=arch=compute_35,code=compute_35 -gencode=arch=compute_52,code=compute_52"
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
        if [ "$MB_PYTHON_OSX_VER" != "10.9" ]; then
            export CXXFLAGS="-stdlib=libc++"
            export CFLAGS="-stdlib=libc++"
        fi
    else
        build_openblas > /dev/null
        install_devtoolset3
        install_cuda_repo
        install_cuda_libs
    fi
    (cd $REPO_DIR && build_faiss)
}

function pip_wheel_cmd {
    local abs_wheelhouse=$1
    if [ -n "$IS_OSX" ]; then
        export FAISS_LDFLAGS="/usr/local/lib/libfaiss.a -framework Accelerate"
    else
        export FAISS_LDFLAGS="-l:libfaiss.a -l:libopenblas.a -lgfortran -lcublas_static -lcudart_static -lculibos"
        export GPU_WRAPPER=true
        if [ "$PYTHON_VERSION" = "3.6" ]; then
            python setup.py sdist --dist-dir $abs_wheelhouse
        fi
    fi
    pip wheel $(pip_opts) -w $abs_wheelhouse --no-deps .
}

function repair_wheelhouse {
    local in_dir=$1
    local out_dir=${2:-$in_dir}
    local plat=${AUDITWHEEL_PLAT:-manylinux2010_x86_64}  # Patch for manylinux2010
    for whl in $in_dir/*.whl; do
        if [[ $whl == *none-any.whl ]]; then  # Pure Python wheel
            if [ "$in_dir" != "$out_dir" ]; then cp $whl $out_dir; fi
        else
            auditwheel repair $whl -w $out_dir/ --plat $plat
            # Remove unfixed if writing into same directory
            if [ "$in_dir" == "$out_dir" ]; then rm $whl; fi
        fi
    done
    chmod -R a+rwX $out_dir
}

function run_tests {
    python --version
    python -c "import faiss, numpy; faiss.Kmeans(10, 20).train(numpy.random.rand(1000, 10).astype(numpy.float32))"
}
