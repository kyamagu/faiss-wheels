# Find requirements.
find_package(SWIG REQUIRED COMPONENTS python)
if(FAISS_ENABLE_SABI)
  find_package(Python REQUIRED COMPONENTS Interpreter Development.SABIModule
                                          NumPy)
else()
  find_package(Python REQUIRED COMPONENTS Interpreter Development.Module NumPy)
endif()
find_package(OpenMP REQUIRED)
if(FAISS_ENABLE_ROCM)
  find_package(hip REQUIRED)
endif()

# Swig configurations.
include(${SWIG_USE_FILE})
set(SWIG_SOURCE_FILE_EXTENSIONS swig)

# Helper to set up Python properties.
function(configure_python_properties target)
  target_include_directories(${target} PRIVATE ${Python_NumPy_INCLUDE_DIRS})
  if(FAISS_ENABLE_SABI)
    # Stable / Limited API build.
    target_compile_definitions(${target}
                               PRIVATE Py_LIMITED_API=${PY_LIMITED_API})
    target_link_libraries(${target} PRIVATE Python::SABIModule)
    if("${SKBUILD_SOABI}" STREQUAL "")
      set(SKBUILD_SOABI "abi3")
    endif()
    if(WIN32)
      set_target_properties(${target} PROPERTIES SUFFIX .${SKBUILD_SOABI}.pyd)
    else()
      set_target_properties(
        ${target} PROPERTIES SUFFIX
                             .${SKBUILD_SOABI}${CMAKE_SHARED_MODULE_SUFFIX})
    endif()
  else()
    # Standard build.
    target_link_libraries(${target} PRIVATE Python::Module)
    if(WIN32)
      set_target_properties(${target} PROPERTIES SUFFIX .pyd)
    else()
      set_target_properties(${target} PROPERTIES SUFFIX
                                                 ${CMAKE_SHARED_MODULE_SUFFIX})
    endif()
  endif()
endfunction()

# Helper to set up GPU-related properties.
function(configure_gpu_properties target)
  target_compile_definitions(${target} PRIVATE FAISS_ENABLE_GPU)
  set_property(
    TARGET ${target}
    APPEND
    PROPERTY SWIG_COMPILE_DEFINITIONS GPU_WRAPPER)
  if(FAISS_ENABLE_CUDA)
    target_include_directories(${target} PRIVATE ${CUDAToolkit_INCLUDE_DIRS})
    if(FAISS_ENABLE_CUVS)
      set_property(
        TARGET ${target}
        APPEND
        PROPERTY SWIG_COMPILE_DEFINITIONS FAISS_ENABLE_CUVS)
    endif()
  elseif(FAISS_ENABLE_ROCM)
    target_link_libraries(${target} PRIVATE hip::host)
    set_property(
      TARGET ${target}
      APPEND
      PROPERTY SWIG_COMPILE_DEFINITIONS FAISS_ENABLE_ROCM)
  endif()
endfunction()

# Helper to build and install faiss SWIG extensions.
function(configure_extension suffix)
  # Configure swigfaiss extension.
  set(target "swigfaiss${suffix}")
  set(swig_source_file
      ${CMAKE_CURRENT_SOURCE_DIR}/../third-party/faiss/faiss/python/swigfaiss.swig
  )
  set_source_files_properties(
    ${swig_source_file}
    PROPERTIES
      CPLUSPLUS ON
      USE_TARGET_INCLUDE_DIRECTORIES TRUE
      DEPENDS
      "${FAISS_HEADERS};$<$<BOOL:${FAISS_ENABLE_GPU}>:${FAISS_GPU_HEADERS}>"
      COMPILE_OPTIONS -doxygen
      SWIG_MODULE_NAME ${target})
  swig_add_library(
    ${target}
    TYPE SHARED
    LANGUAGE python
    SOURCES ${swig_source_file})

  # Set up platform-specific flags.
  if(WIN32)
    set_property(TARGET ${target} PROPERTY SWIG_COMPILE_DEFINITIONS SWIGWIN)
    target_compile_options(${target} PRIVATE /bigobj)
  elseif(NOT APPLE)
    set_property(TARGET ${target} PROPERTY SWIG_COMPILE_DEFINITIONS
                                           SWIGWORDSIZE64)
  endif()

  # Set up MKL flags.
  if(BLA_VENDOR MATCHES "Intel*")
    target_link_libraries(${target} PRIVATE MKL::MKL)
  endif()

  # Set up GPU flags.
  if(FAISS_ENABLE_GPU)
    configure_gpu_properties(${target})
  endif()

  configure_python_properties(${target})
  target_link_libraries(
    ${target} PRIVATE "faiss${suffix}" faiss_python_callbacks Python::NumPy
                      OpenMP::OpenMP_CXX)

  # Install the SWIG-generated files and the built shared library.
  get_property(
    support_files
    TARGET ${target}
    PROPERTY SWIG_SUPPORT_FILES)
  install(TARGETS ${target} DESTINATION ${PYTHON_PACKAGE_NAME})
  install(FILES ${support_files} DESTINATION ${PYTHON_PACKAGE_NAME})
endfunction()

# Build the callback lib.
function(configure_callback_lib)
  add_library(
    faiss_python_callbacks STATIC EXCLUDE_FROM_ALL
    ${CMAKE_CURRENT_SOURCE_DIR}/../third-party/faiss/faiss/python/python_callbacks.cpp
  )
  set_property(TARGET faiss_python_callbacks PROPERTY POSITION_INDEPENDENT_CODE
                                                      ON)
  target_include_directories(
    faiss_python_callbacks
    PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/../third-party/faiss/)
  target_include_directories(faiss_python_callbacks
                             PRIVATE ${Python_INCLUDE_DIRS})
  if(FAISS_ENABLE_SABI)
    target_compile_definitions(faiss_python_callbacks
                               PRIVATE Py_LIMITED_API=${PY_LIMITED_API})
  endif()
endfunction()

# Build extensions based on the optimization level.
configure_callback_lib()
if("generic" IN_LIST FAISS_OPT_LEVELS)
  configure_extension("")
endif()
if("avx2" IN_LIST FAISS_OPT_LEVELS)
  configure_extension(_avx2)
endif()
if("avx512" IN_LIST FAISS_OPT_LEVELS)
  configure_extension(_avx512)
endif()
if("avx512_spr" IN_LIST FAISS_OPT_LEVELS)
  configure_extension(_avx512_spr)
endif()
if("sve" IN_LIST FAISS_OPT_LEVELS)
  configure_extension(_sve)
endif()

# Package Python source files.
install(
  DIRECTORY ../third-party/faiss/faiss/python/
  DESTINATION ${PYTHON_PACKAGE_NAME}
  FILES_MATCHING
  PATTERN "*.py"
  PATTERN "setup.py" EXCLUDE)
install(
  DIRECTORY ../third-party/faiss/contrib
  DESTINATION ${PYTHON_PACKAGE_NAME}
  FILES_MATCHING
  PATTERN "*.py")
