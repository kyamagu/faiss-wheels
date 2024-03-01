import os
import sys
from typing import List

import numpy as np
from setuptools import Extension, setup
from setuptools.command.build_py import build_py

# Faiss conifgurations
FAISS_INSTALL_PREFIX = os.getenv("FAISS_INSTALL_PREFIX", "/usr/local")
FAISS_OPT_LEVEL = os.getenv("FAISS_OPT_LEVEL", "generic")
FAISS_ENABLE_GPU = (os.getenv("FAISS_ENABLE_GPU", "").lower() in ("on", "true"))

# Common configurations
FAISS_ROOT = "faiss"  # relative to the setup.py file

DEFINE_MACROS = [("FINTEGER", "int")]
INCLUDE_DIRS = [
    np.get_include(), FAISS_ROOT, os.path.join(FAISS_INSTALL_PREFIX, "include")]
LIBRARY_DIRS: List[str] = [os.path.join(FAISS_INSTALL_PREFIX, "lib")]
EXTRA_COMPILE_ARGS: List[str] = []
EXTRA_LINK_ARGS: List[str] = []
SWIG_OPTS = ["-c++", "-Doverride=", "-doxygen", f"-I{FAISS_ROOT}"] + [
    f"-I{x}" for x in INCLUDE_DIRS]

# GPU options
if FAISS_ENABLE_GPU:
    CUDA_HOME = os.getenv("CUDA_HOME", "/usr/local/cuda")
    INCLUDE_DIRS += [os.path.join(CUDA_HOME, "include")]
    LIBRARY_DIRS += [os.path.join(CUDA_HOME, "lib64")]
    SWIG_OPTS += ["-I" + os.path.join(CUDA_HOME, "include"), "-DGPU_WRAPPER"]


# Platform options
def win32_options(
    extra_compile_args: List[str],
    extra_link_args: List[str],
    swig_opts: List[str],
) -> dict:
    """Windows options."""
    return dict(
        extra_compile_args=extra_compile_args + [
            "/openmp:llvm",
            "/std:c++17",
            "/Zc:inline",
            "/wd4101",  # unreferenced local variable.
            "/MD",  # Bugfix: https://bugs.python.org/issue38597
        ],
        extra_link_args=["/OPT:ICF", "/OPT:REF"] + (
            extra_link_args or ["faiss.lib", "openblas.lib"]),
        swig_opts=swig_opts + ["-DSWIGWIN"],
    )


def linux_options(
    extra_compile_args: List[str],
    extra_link_args: List[str],
    swig_opts: List[str],
) -> dict:
    """Linux options."""
    default_link_args = [
        "-l:libfaiss.a",
        "-l:libopenblas.a",
        "-lgfortran",
    ]
    if FAISS_ENABLE_GPU:
        default_link_args += [
            "-lcublas_static",
            "-lcublasLt_static",
            "-lcudart_static",
            "-lculibos",
        ]
    return dict(
        extra_compile_args=extra_compile_args + [
            "-std=c++17",
            "-Wno-sign-compare",
            "-fopenmp",
            "-fdata-sections",
            "-ffunction-sections",
        ],
        extra_link_args=[
            "-fopenmp",
            "-lrt",
            "-s",
            "-Wl,--gc-sections",
        ] + (extra_link_args or default_link_args),
        swig_opts=swig_opts + ["-DSWIGWORDSIZE64"],
    )


def darwin_options(
    extra_compile_args: List[str],
    extra_link_args: List[str],
    swig_opts: List[str],
) -> dict:
    """macOS options."""
    return dict(
        extra_compile_args=extra_compile_args + [
            "-std=c++17",
            "-Wno-sign-compare",
            "-Xpreprocessor",
            "-fopenmp",
        ],
        extra_link_args=[
            "-Xpreprocessor",
            "-fopenmp",
            "-dead_strip",
        ] + (extra_link_args or [
            "-lfaiss",
            "-lomp",
            "-framework",
            "Accelerate",
        ]),
        swig_opts=swig_opts,
    )


PLATFORM_CONFIGS = {
    "win32": win32_options,
    "linux": linux_options,
    "darwin": darwin_options,
}


# Optimization options
def generic_options(
    extra_compile_args: List[str],
    extra_link_args: List[str],
    swig_opts: List[str],
) -> dict:
    """Add generic extension options."""
    return dict(
        name="faiss._swigfaiss",
        extra_compile_args=extra_compile_args,
        extra_link_args=extra_link_args,
        swig_opts=swig_opts,
    )


def avx2_options(
    extra_compile_args: List[str],
    extra_link_args: List[str],
    swig_opts: List[str],
) -> dict:
    """Add AVX2 extension options."""
    if sys.platform == "win32":
        flags = ["/arch:AVX2", "/bigobj"]
    else:
        flags = ["-mavx2", "-mfma", "-mf16c", "-mpopcnt"]
    return dict(
        name="faiss._swigfaiss_avx2",
        extra_compile_args=extra_compile_args + flags,
        extra_link_args=[x.replace("faiss", "faiss_avx2") for x in extra_link_args],
        swig_opts=swig_opts + ["-module", "swigfaiss_avx2"],
    )


def avx512_options(
    extra_compile_args: List[str],
    extra_link_args: List[str],
    swig_opts: List[str],
) -> dict:
    """Add AVX512 extension options."""
    if sys.platform == "win32":
        flags = ["/arch:AVX512", "/bigobj"]
    else:
        flags = [
            "-mavx2", "-mfma", "-mf16c", "-mavx512f", "-mavx512cd", "-mavx512vl",
            "-mavx512dq", "-mavx512bw", "-mpopcnt"
        ]
    return dict(
        name="faiss._swigfaiss_avx512",
        extra_compile_args=extra_compile_args + flags,
        extra_link_args=[x.replace("faiss", "faiss_avx512") for x in extra_link_args],
        swig_opts=swig_opts + ["-module", "swigfaiss_avx512"],
    )


OPT_CONFIGS = {
    "generic": [generic_options],
    "avx2": [generic_options, avx2_options],
    "avx512": [generic_options, avx2_options, avx512_options],
}

platform_config = PLATFORM_CONFIGS[sys.platform](
    EXTRA_COMPILE_ARGS, EXTRA_LINK_ARGS, SWIG_OPTS)

ext_modules = [
    Extension(
        sources=[
            os.path.join(FAISS_ROOT, "faiss", "python", "swigfaiss.i"),
            os.path.join(FAISS_ROOT, "faiss", "python", "python_callbacks.cpp"),
        ],
        depends=[os.path.join(FAISS_ROOT, "faiss", "python", "python_callbacks.h")],
        language="c++",
        define_macros=DEFINE_MACROS,  # type: ignore
        include_dirs=INCLUDE_DIRS,
        library_dirs=LIBRARY_DIRS,
        **option_fn(**platform_config),
    )
    for option_fn in OPT_CONFIGS[FAISS_OPT_LEVEL]
]


class CustomBuildPy(build_py):
    """Run build_ext before build_py to compile swig code."""
    def run(self):
        self.run_command("build_ext")
        return build_py.run(self)


setup(
    packages=["faiss", "faiss.contrib"],
    package_dir={
        "faiss": os.path.join(FAISS_ROOT, "faiss", "python"),
        "faiss.contrib": os.path.join(FAISS_ROOT, "contrib"),
    },
    include_package_data=False,
    package_data={"": ["*.i", "*.h"]},
    ext_modules=ext_modules,
    cmdclass={"build_py": CustomBuildPy},
)
