# Top-level default configuration for faiss-build
include_guard()

# Optimization levels; e.g., "generic,avx2"
set(FAISS_OPT_LEVELS
    "generic"
    CACHE
      STRING
      "Optimization level, comma-separated string of <generic|avx2|avx512|avx512_spr|sve>."
)
if(DEFINED ENV{FAISS_OPT_LEVELS})
  set(FAISS_OPT_LEVELS
      $ENV{FAISS_OPT_LEVELS}
      CACHE STRING "Optimization level." FORCE)
endif()
string(REPLACE "," ";" FAISS_OPT_LEVELS "${FAISS_OPT_LEVELS}")
list(TRANSFORM FAISS_OPT_LEVELS STRIP)
set(FAISS_OPT_LEVELS_VALUES "generic;avx2;avx512;avx512_spr;sve")
foreach(level IN LISTS FAISS_OPT_LEVELS)
  if(NOT level IN_LIST FAISS_OPT_LEVELS_VALUES)
    message(FATAL_ERROR "Invalid FAISS_OPT_LEVELS value: ${level}.\
        Supported values are combination of: ${FAISS_OPT_LEVELS_VALUES}")
  endif()
endforeach()
if(NOT FAISS_OPT_LEVELS)
  message(FATAL_ERROR "FAISS_OPT_LEVELS is empty.")
endif()
message(STATUS "Faiss optimization levels - ${FAISS_OPT_LEVELS}")

# MKL support.
option(FAISS_ENABLE_MKL "Enable MKL support." OFF)
if(DEFINED ENV{FAISS_ENABLE_MKL})
  set(FAISS_ENABLE_MKL $ENV{FAISS_ENABLE_MKL})
endif()

# GPU supports.
set(FAISS_GPU_SUPPORT
    OFF
    CACHE STRING "GPU support, one of <OFF|CUDA|CUVS|ROCM>.")
if(DEFINED ENV{FAISS_GPU_SUPPORT})
  set(FAISS_GPU_SUPPORT
      $ENV{FAISS_GPU_SUPPORT}
      CACHE STRING "GPU support, one of <OFF|CUDA|CUVS|ROCM>." FORCE)
endif()
string(TOUPPER ${FAISS_GPU_SUPPORT} FAISS_GPU_SUPPORT)
set(FAISS_GPU_SUPPORT_VALUES "OFF;CUDA;CUVS;ROCM")
set_property(CACHE FAISS_GPU_SUPPORT PROPERTY STRINGS FAISS_GPU_SUPPORT_VALUES)
if(NOT FAISS_GPU_SUPPORT IN_LIST FAISS_GPU_SUPPORT_VALUES)
  message(FATAL_ERROR "Invalid FAISS_GPU_SUPPORT value: ${FAISS_GPU_SUPPORT}.\
  Supported values are: ${FAISS_GPU_SUPPORT_VALUES}")
endif()

# Expand variables for GPU support in the faiss cmake config.
if(FAISS_GPU_SUPPORT)
  set(FAISS_ENABLE_GPU ON)
  if(FAISS_GPU_SUPPORT STREQUAL "CUDA")
    set(FAISS_ENABLE_CUDA ON) # This is not a faiss cmake config variable.
  elseif(FAISS_GPU_SUPPORT STREQUAL "CUVS")
    set(FAISS_ENABLE_CUDA ON)
    set(FAISS_ENABLE_CUVS ON)
  elseif(FAISS_GPU_SUPPORT STREQUAL "ROCM")
    set(FAISS_ENABLE_ROCM ON)
  endif()
else()
  set(FAISS_ENABLE_GPU OFF)
endif()
message(STATUS "Faiss GPU support - ${FAISS_GPU_SUPPORT}")

# LTO option.
option(FAISS_USE_LTO "Enable Link Time Optimization (LTO)." ON)

# CUDA static link option.
option(FAISS_GPU_STATIC "Enable static linking of CUDA libraries." OFF)

# Python package name.
set(PYTHON_PACKAGE_NAME
    "faiss"
    CACHE STRING "Python package name, default to faiss")

# Py_LIMITED_API value, default to <0x03090000>. TODO: Derive the hex value from
# SKBUILD_SABI_VERSION.
set(PY_LIMITED_API
    "0x03090000"
    CACHE STRING "Py_LIMITED_API macro value")

# Default overrides for building Python bindings.
set(FAISS_ENABLE_EXTRAS OFF)
set(BUILD_TESTING OFF)
set(FAISS_ENABLE_PYTHON OFF) # We use our own Python build configuration.

if(SKBUILD_SABI_VERSION)
  set(FAISS_ENABLE_SABI ON)
  message(STATUS "Stable ABI - ${SKBUILD_SABI_VERSION}")
else()
  set(FAISS_ENABLE_SABI OFF)
  message(STATUS "Stable ABI - OFF")
endif()

# Helper to define default build options.
macro(configure_default_options)
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  set(CMAKE_CXX_EXTENSIONS OFF)

  # Set up platform-specific global flags.
  if(APPLE)
    configure_apple_platform()
  elseif(UNIX)
    configure_linux_platform()
  elseif(WIN32)
    configure_win32_platform()
  endif()

  # Set up global CUDA flags.
  if(FAISS_ENABLE_CUDA)
    configure_cuda_flags()
  elseif(FAISS_ENABLE_ROCM)
    configure_rocm_flags()
  endif()

  # Use ccache if available.
  find_program(CCACHE_FOUND ccache)
  if(CCACHE_FOUND)
    message(STATUS "ccache enabled")
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
  endif()
endmacro()

# Helper to configure Apple platform
macro(configure_apple_platform)
  add_compile_options(-Wno-unused-function -Wno-format
                      -Wno-deprecated-declarations)
  add_link_options(-dead_strip)
  # Set OpenMP_ROOT from Homebrew.
  if(NOT ENV{OpenMP_ROOT})
    find_program(HOMEBREW_FOUND brew)
    if(HOMEBREW_FOUND)
      execute_process(
        COMMAND brew --prefix libomp
        OUTPUT_VARIABLE HOMEBREW_LIBOMP_PREFIX
        OUTPUT_STRIP_TRAILING_WHITESPACE)
      set(ENV{OpenMP_ROOT} ${HOMEBREW_LIBOMP_PREFIX})
    endif()
  endif()
  # Set MACOSX_DEPLOYMENT_TARGET. NOTE: This is a workaround for the
  # compatibility with libomp on Homebrew. For C++17 compatibility, the minimum
  # required version is 10.13.
  if(NOT DEFINED CMAKE_OSX_DEPLOYMENT_TARGET)
    execute_process(
      COMMAND sw_vers -productVersion
      OUTPUT_VARIABLE MACOSX_VERSION
      OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(${MACOSX_VERSION} VERSION_LESS "14.0")
      set(CMAKE_OSX_DEPLOYMENT_TARGET 13.0)
    else()
      set(CMAKE_OSX_DEPLOYMENT_TARGET 14.0)
    endif()
  endif()
  message(STATUS "macOS deployment target - ${CMAKE_OSX_DEPLOYMENT_TARGET}")
endmacro()

# Helper to configure Win32 platform
macro(configure_win32_platform)
  # A few of warning suppressions for Windows.
  if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    add_compile_options(/wd4101 /wd4267 /wd4477)
    add_link_options(/ignore:4217)
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    add_compile_options(-Wno-unused-function -Wno-format
                        -Wno-deprecated-declarations)
    add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
    add_link_options(/ignore:4217)
  endif()
endmacro()

# Helper to configure Linux platform
macro(configure_linux_platform)
  add_compile_options(-fdata-sections -ffunction-sections)
  add_link_options(-Wl,--gc-sections -Wl,--strip-all)
  if(FAISS_ENABLE_MKL)
    configure_intel_mkl()
  endif()
endmacro()

# Helper to configure default MKL setup.
macro(configure_intel_mkl)
  if(DEFINED ENV{MKLROOT})
    list(APPEND CMAKE_PREFIX_PATH "$ENV{MKLROOT}")
  elseif(EXISTS /opt/intel/oneapi/mkl/latest)
    # Assume oneAPI is installed at the default location.
    list(APPEND CMAKE_PREFIX_PATH "/opt/intel/oneapi/mkl/latest")
  endif()

  # Optional MKL configuration via environment variables.
  set(MKL_INTERFACE lp64)  # faiss uses 32-bit integers for indices.
  if(DEFINED ENV{MKL_LINK})
    set(MKL_LINK $ENV{MKL_LINK})
  else()
    set(MKL_LINK "static")  # Override the default "dynamic" linking.
  endif()
  if(DEFINED ENV{MKL_THREADING})
    set(MKL_THREADING $ENV{MKL_THREADING})  # Default is "intel_thread".
  else()
    set(MKL_THREADING "gnu_thread")  # Override the default "intel_thread".
  endif()

  find_package(MKL REQUIRED)
  set(FAISS_ENABLE_MKL OFF)  # faiss cmake is not compatible with oneAPI MKL.
  set(MKL_LIBRARIES MKL::MKL)  # faiss uses MKL_LIBRARIES to set target linking.

  if(MKL_THREADING STREQUAL "intel_thread")
    # Set OpenMP variables for Intel MKL.
    set(OpenMP_CXX_LIB_NAMES libiomp5)
    # Only dynamic linking is supported in MKLConfig.cmake.
    set(OpenMP_libiomp5_LIBRARY "${MKL_ROOT}/../../compiler/latest/lib/libiomp5.so")
  endif()
endmacro()

# Helper to configure default CUDA setup.
macro(configure_cuda_flags)
  if(NOT CMAKE_CUDA_COMPILER)
    # Enabling CUDA language support requires nvcc available. Here, we use
    # FindCUDAToolkit to detect nvcc executable.
    find_package(CUDAToolkit REQUIRED)
    set(CMAKE_CUDA_COMPILER ${CUDAToolkit_NVCC_EXECUTABLE})
  endif()
  # Set default CUDA architecture to all-major.
  if(NOT CMAKE_CUDA_ARCHITECTURES)
    set(CMAKE_CUDA_ARCHITECTURES all-major)
  endif()
  if(NOT CMAKE_CUDA_FLAGS)
    set(CMAKE_CUDA_FLAGS -Wno-deprecated-gpu-targets)
  endif()
  # NOTE: NVCC has '-forward-unknown-to-host-compiler' option set by default. It
  # is safe to use compiler flags without `-Xcompiler=` option.
endmacro()

# Helper to configure default ROCm setup.
macro(configure_rocm_flags)
  if(NOT CMAKE_HIP_ARCHITECTURES)
    # Check supported GPUs at the ROCm official documentation:
    # https://rocm.docs.amd.com/projects/install-on-linux/en/latest/reference/system-requirements.html
    set(CMAKE_HIP_ARCHITECTURES
        gfx908;gfx90a;gfx942;gfx1030;gfx1100;gfx1101;gfx1200;gfx1201)
  endif()
  if(NOT CMAKE_HIP_FLAGS)
    set(CMAKE_HIP_FLAGS
        "-Wno-deprecated-pragma -Wno-unused-result -Wno-deprecated-declarations"
    )
  endif()
endmacro()
