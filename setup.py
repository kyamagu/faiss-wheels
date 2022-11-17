import os
import sys

from setuptools import setup
from setuptools.command.build_py import build_py
from setuptools.extension import Extension

NAME = 'faiss-cpu'
VERSION = '1.7.3'

LONG_DESCRIPTION = """
Faiss is a library for efficient similarity search and clustering of dense
vectors. It contains algorithms that search in sets of vectors of any size, up
to ones that possibly do not fit in RAM. It also contains supporting code for
evaluation and parameter tuning. Faiss is written in C++ with complete wrappers
for Python/numpy. It is developed by Facebook AI Research.
"""

# CMake variables for faiss
FAISS_ROOT = os.getenv('FAISS_ROOT', 'faiss')
FAISS_INCLUDE = os.getenv('FAISS_INCLUDE', os.path.join('/usr/local/include'))
FAISS_LDFLAGS = os.getenv('FAISS_LDFLAGS')
FAISS_OPT_LEVEL = os.getenv('FAISS_OPT_LEVEL', 'generic')
FAISS_ENABLE_GPU = (
    os.getenv('FAISS_ENABLE_GPU', '').lower() in ('on', 'true')
)


class get_numpy_include(object):
    """
    Helper class to determine the numpy include path.

    The purpose of this class is to postpone importing numpy
    until it is actually installed, so that the ``get_include()``
    method can be invoked.
    """
    def __str__(self):
        import numpy as np
        return np.get_include()


# Platform-specific configurations
DEFINE_MACROS = [
    ('FINTEGER', 'int'),
]
INCLUDE_DIRS = [
    get_numpy_include(),
    FAISS_INCLUDE,
    FAISS_ROOT,
]
LIBRARY_DIRS = []
EXTRA_COMPILE_ARGS = []
EXTRA_LINK_ARGS = FAISS_LDFLAGS.split() if FAISS_LDFLAGS is not None else []
SWIG_OPTS = [
    '-c++',
    '-Doverride=',
    '-I' + FAISS_INCLUDE,
    '-I' + FAISS_ROOT,
    '-doxygen',
]

if sys.platform == 'win32':
    EXTRA_COMPILE_ARGS += [
        '/openmp',
        '/std:c++17',
        '/Zc:inline',
        '/wd4101',  # unreferenced local variable.
        '/MD',  # Bugfix: https://bugs.python.org/issue38597
    ]
    EXTRA_LINK_ARGS += [
        '/OPT:ICF',
        '/OPT:REF',
    ]
    if FAISS_LDFLAGS is None:
        EXTRA_LINK_ARGS += [
            'faiss.lib',
            'openblas.lib',
        ]
    SWIG_OPTS += ['-DSWIGWIN']
elif sys.platform == 'linux':
    EXTRA_COMPILE_ARGS += [
        '-std=c++11',
        '-Wno-sign-compare',
        '-fopenmp',
        '-fdata-sections',
        '-ffunction-sections',
    ]
    EXTRA_LINK_ARGS += [
        '-fopenmp',
        '-lrt',
        '-s',
        '-Wl,--gc-sections',
    ]
    if FAISS_LDFLAGS is None:
        EXTRA_LINK_ARGS += [
            '-L/usr/local/lib',
            '-l:libfaiss.a',
            '-l:libopenblas.a',
            '-lgfortran',
        ]
        if FAISS_ENABLE_GPU:
            EXTRA_LINK_ARGS += [
                '-lcublas_static',
                '-lcublasLt_static',
                '-lcudart_static',
                '-lculibos'
            ]
    SWIG_OPTS += ['-DSWIGWORDSIZE64']
elif sys.platform == 'darwin':
    EXTRA_COMPILE_ARGS += [
        '-std=c++11',
        '-Wno-sign-compare',
        '-Xpreprocessor',
        '-fopenmp',
    ]
    EXTRA_LINK_ARGS += [
        '-Xpreprocessor',
        '-fopenmp',
        '-dead_strip',
    ]
    if FAISS_LDFLAGS is None:
        EXTRA_LINK_ARGS += [
            '-L/usr/local/lib',
            '-lfaiss',
            '-lomp',
            '-framework',
            'Accelerate',
        ]

if FAISS_ENABLE_GPU:
    NAME = 'faiss-gpu'
    CUDA_HOME = os.getenv('CUDA_HOME', '/usr/local/cuda')
    INCLUDE_DIRS += [os.path.join(CUDA_HOME, 'include')]
    LIBRARY_DIRS += [os.path.join(CUDA_HOME, 'lib64')]
    SWIG_OPTS += ['-I' + os.path.join(CUDA_HOME, 'include'), '-DGPU_WRAPPER']


class CustomBuildPy(build_py):
    """Run build_ext before build_py to compile swig code."""
    def run(self):
        self.run_command("build_ext")
        return build_py.run(self)


_swigfaiss = Extension(
    'faiss._swigfaiss',
    sources=[
        os.path.join(FAISS_ROOT, 'faiss', 'python', 'swigfaiss.i'),
        os.path.join(FAISS_ROOT, 'faiss', 'python', 'python_callbacks.cpp'),
    ],
    depends=[os.path.join(FAISS_ROOT, 'faiss', 'python', 'python_callbacks.h')],
    language='c++',
    define_macros=DEFINE_MACROS,
    include_dirs=INCLUDE_DIRS,
    library_dirs=LIBRARY_DIRS,
    extra_compile_args=EXTRA_COMPILE_ARGS,
    extra_link_args=EXTRA_LINK_ARGS,
    swig_opts=SWIG_OPTS + ["-module", "swigfaiss"],
)
ext_modules = [_swigfaiss]

if FAISS_OPT_LEVEL == 'avx2':
    # NOTE: avx2 is only available on x86_64 arch.
    if sys.platform == 'win32':
        EXTRA_COMPILE_ARGS_AVX2 = EXTRA_COMPILE_ARGS + ['/arch:AVX2']
    else:
        EXTRA_COMPILE_ARGS_AVX2 = EXTRA_COMPILE_ARGS + ['-mavx2', '-mpopcnt']

    # TODO: fix this ad-hoc approach to specify avx2 lib.
    EXTRA_LINK_ARGS_AVX2 = [x.replace("faiss", "faiss_avx2") for x in EXTRA_LINK_ARGS]

    _swigfaiss_avx2 = Extension(
        'faiss._swigfaiss_avx2',
        sources=[
            os.path.join(FAISS_ROOT, 'faiss', 'python', 'swigfaiss.i'),
            os.path.join(FAISS_ROOT, 'faiss', 'python', 'python_callbacks.cpp'),
        ],
        depends=[os.path.join(FAISS_ROOT, 'faiss', 'python', 'python_callbacks.h')],
        language='c++',
        define_macros=DEFINE_MACROS,
        include_dirs=INCLUDE_DIRS,
        library_dirs=LIBRARY_DIRS,
        extra_compile_args=EXTRA_COMPILE_ARGS_AVX2,
        extra_link_args=EXTRA_LINK_ARGS_AVX2,
        swig_opts=SWIG_OPTS + ["-module", "swigfaiss_avx2"],
    )
    ext_modules.append(_swigfaiss_avx2)

setup(
    name=NAME,
    version=VERSION,
    description=(
        'A library for efficient similarity search and clustering of dense '
        'vectors.'
    ),
    long_description=LONG_DESCRIPTION,
    url='https://github.com/kyamagu/faiss-wheels',
    author='Kota Yamaguchi',
    author_email='KotaYamaguchi1984@gmail.com',
    license='MIT',
    keywords='search nearest neighbors',
    setup_requires=['numpy'],
    packages=['faiss', 'faiss.contrib'],
    package_dir={
        'faiss': os.path.join(FAISS_ROOT, 'faiss', 'python'),
        'faiss.contrib': os.path.join(FAISS_ROOT, 'contrib'),
    },
    package_data={'faiss': ['*.i', '*.h']},
    ext_modules=ext_modules,
    cmdclass={'build_py': CustomBuildPy},
    classifiers=[
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'Intended Audience :: Science/Research',
        'License :: OSI Approved :: MIT License',
        'Operating System :: MacOS :: MacOS X',
        'Operating System :: Microsoft :: Windows',
        'Operating System :: POSIX',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
        'Topic :: Scientific/Engineering :: Artificial Intelligence',
    ],
)
