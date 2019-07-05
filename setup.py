"""faiss build for python.

Build
-----

On Linux:

GPU support is automatically built when nvcc compiler is available. Set
`CUDA_HOME` environment variable to specify where CUDA is installed.

    apt-get install swig libblas-dev liblapack-dev
    pip install numpy setuptools
    python setup.py bdist_wheel

On macOS:

    brew install llvm swig openblas
    pip install numpy setuptools
    python setup.py bdist_wheel

"""
from setuptools import setup
from setuptools.extension import Extension
from distutils.command.build import build
from distutils.command.build_ext import build_ext
from distutils.util import get_platform
import os

SOURCES = [
    'python/swigfaiss.i',
]

HEADERS = [
    'AutoTune.h',
    'AuxIndexStructures.h',
    'Clustering.h',
    'FaissException.h',
    'Heap.h',
    'Index.h',
    'IndexBinary.h',
    'IndexBinaryFlat.h',
    'IndexBinaryIVF.h',
    'IndexFlat.h',
    'IndexHNSW.h',
    'IndexIVF.h',
    'IndexIVFFlat.h',
    'IndexIVFPQ.h',
    'IndexLSH.h',
    'IndexPQ.h',
    'IndexScalarQuantizer.h',
    'MetaIndexes.h',
    'OnDiskInvertedLists.h',
    'PolysemousTraining.h',
    'ProductQuantizer.h',
    'VectorTransform.h',
    'hamming.h',
    'index_io.h',
    'utils.h',
]


class CustomBuild(build):
    """Build ext first so that swig-generated file is packaged.
    """
    sub_commands = [
        ('build_ext', build.has_ext_modules),
        ('build_py', build.has_pure_modules),
        ('build_clib', build.has_c_libraries),
        ('build_scripts', build.has_scripts),
    ]


class CustomBuildExt(build_ext):
    """Customize extension build by injecting nvcc.
    """

    def run(self):
        import numpy
        self.include_dirs.append(numpy.get_include())
        build_ext.run(self)

    def build_extensions(self):
        # Suppress -Wstrict-prototypes bug in python.
        # https://stackoverflow.com/questions/8106258/
        self._remove_flag('-Wstrict-prototypes')
        # GCC with -fwrapv will result in segfault.
        self._remove_flag('-fwrapv')
        # Clang-specific flag.
        compiler_name = self.compiler.compiler[0]
        if 'gcc' in compiler_name or 'g++' in compiler_name:
            self._remove_flag('-Wshorten-64-to-32')

        self.swig = self.swig or os.getenv('SWIG')
        build_ext.build_extensions(self)

    def _remove_flag(self, flag):
        compiler = self.compiler.compiler
        compiler_cxx = self.compiler.compiler_cxx
        compiler_so = self.compiler.compiler_so
        for args in (compiler, compiler_cxx, compiler_so):
            while flag in args:
                args.remove(flag)


_swigfaiss = Extension(
    '_swigfaiss',
    sources=SOURCES,
    depends=HEADERS,
    define_macros=[('FINTEGER', 'int')],
    language='c++',
    include_dirs=[os.getenv('FAISS_INCLUDE', '/usr/local/include/faiss')],
    extra_compile_args=[
        '-std=c++11', '-mavx2', '-mf16c', '-msse4', '-mpopcnt', '-m64',
        '-Wno-sign-compare', '-fopenmp'
    ],
    extra_link_args=[os.getenv('FAISS_LIB', '/usr/local/lib/libfaiss.a')],
    swig_opts=['-c++', '-Doverride='] +
    ([] if 'macos' in get_platform() else ['-DSWIGWORDSIZE64']),
)

LONG_DESCRIPTION = """
Faiss is a library for efficient similarity search and clustering of dense
vectors. It contains algorithms that search in sets of vectors of any size, up
to ones that possibly do not fit in RAM. It also contains supporting code for
evaluation and parameter tuning. Faiss is written in C++ with complete wrappers
for Python/numpy. It is developed by Facebook AI Research.
"""

setup(
    name='faiss-cpu',
    version='1.5.3',
    description=(
        'A library for efficient similarity search and clustering of dense '
        'vectors.'
    ),
    long_description=LONG_DESCRIPTION,
    url='https://github.com/kyamagu/faiss-wheels',
    author='Kota Yamaguchi',
    author_email='KotaYamaguchi1984@gmail.com',
    license='BSD',
    keywords='search nearest neighbors',
    cmdclass={
        'build': CustomBuild,
        'build_ext': CustomBuildExt,
    },
    install_requires=['numpy'],
    package_dir={'faiss': 'python'},
    packages=['faiss'],
    ext_modules=[_swigfaiss]
)
