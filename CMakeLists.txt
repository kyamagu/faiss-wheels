cmake_minimum_required(VERSION 3.24...4.0)

# Guard for standalone CMake build instead of scikit-build-core.
if(NOT "${SKBUILD}" STREQUAL "2")
  # TODO: extract information from pyproject.toml
  message(STATUS "Standalone CMake build detected.")
  set(SKBUILD_PROJECT_NAME
      "faiss-cpu"
      CACHE STRING "Project name")
  set(SKBUILD_PROJECT_VERSION
      "1.12.0"
      CACHE STRING "Project version")
  set(SKBUILD_SABI_VERSION
      ""
      CACHE STRING "SABI version")
  set(SKBUILD_SOABI
      "abi3"
      CACHE STRING "SOABI tag")
endif()

# Project configuration.
project(
  ${SKBUILD_PROJECT_NAME}
  VERSION ${SKBUILD_PROJECT_VERSION}
  DESCRIPTION "Python bindings for faiss."
  LANGUAGES CXX)

# Include top-level configuration.
include(cmake/default_config.cmake)

# Global build configuration when this project is the top-level project.
if(CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME)
  configure_default_options()
endif()

# Import targets from the third-party/faiss directory.
add_subdirectory(third-party/faiss EXCLUDE_FROM_ALL)

# Python bindings.
add_subdirectory(python)
