# Copyright Advanced Micro Devices, Inc.
# SPDX-License-Identifier: MIT

# Minimal OpenBLAS build for the HIP CPU-only configuration.
#
# This is modeled on third-party/host-blas/CMakeLists.txt for how it wires into
# TheRock's artifact and package machinery, but the OpenBLAS build itself is
# kept portable and minimal:
#   * LP64 only (no ILP64/INTERFACE64 variant)
#   * TARGET=GENERIC so it builds on x86_64, riscv64, and other hosts
#   * No DYNAMIC_ARCH (not portable to riscv)
#   * Shared library, installed to the root lib/ with the upstream libopenblas
#     name, plus a minimal OpenBLAS/cblas CMake package.

if(NOT CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    # When included in TheRock, download sources and set up the sub-project.
    set(_source_dir "${CMAKE_CURRENT_BINARY_DIR}/source")
    set(_download_stamp "${_source_dir}/download.stamp")

    # Prefer a locally-downloaded source tarball (dropped into
    # optional-sources/downloads/) so the build works without network access.
    # Otherwise, fetch from GitHub.
    set(_openblas_local_source
      "${CMAKE_SOURCE_DIR}/optional-sources/downloads/OpenBLAS-0.3.34.tar.gz")
    if(EXISTS "${_openblas_local_source}")
      set(_openblas_url "${_openblas_local_source}")
    else()
      set(_openblas_url
        "https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.34/OpenBLAS-0.3.34.tar.gz")
    endif()

    therock_subproject_fetch(therock-openblas-sources
      CMAKE_PROJECT
      SOURCE_DIR "${_source_dir}"
      URL "${_openblas_url}"
      URL_HASH SHA256=cd7e129868320cc2d033afa920e31202dfe0b8066a5b66661900ccc0f197dfed
      TOUCH "${_download_stamp}"
    )

    therock_cmake_subproject_declare(therock-openblas
      USE_DIST_AMDGPU_TARGETS
      BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/openblas"
      BACKGROUND_BUILD
      EXCLUDE_FROM_ALL
      NO_MERGE_COMPILE_COMMANDS
      OUTPUT_ON_FAILURE
      EXTERNAL_SOURCE_DIR .
      CMAKE_ARGS
        "-DSOURCE_DIR=${_source_dir}"
        -DBUILD_SHARED_LIBS=ON
        -DC_LAPACK=ON
        -DTARGET=GENERIC
        -DDYNAMIC_ARCH=OFF
        -DBUILD_TESTING=OFF
      EXTRA_DEPENDS
        "${_download_stamp}"
    )
    therock_cmake_subproject_provide_package(therock-openblas OpenBLAS lib/cmake/OpenBLAS)
    therock_cmake_subproject_provide_package(therock-openblas cblas lib/cmake/OpenBLAS)
    therock_cmake_subproject_activate(therock-openblas)

    therock_test_validate_shared_lib(
      PATH openblas/dist/lib
      LIB_NAMES libopenblas.so
    )

    therock_provide_artifact(openblas
      DESCRIPTOR artifact-OpenBLAS.toml
      TARGET_NEUTRAL
      COMPONENTS
        dbg
        dev
        doc
        lib
        run
      SUBPROJECT_DEPS therock-openblas
    )
    return()
endif()

# Otherwise, this is the sub-project build.
cmake_minimum_required(VERSION 3.25)
project(OpenBLAS_BUILD)

# Install to the root lib/ and include/ (the default OpenBLAS layout), rather
# than the lib/host-math/ prefix used by host-blas.
set(CMAKE_INSTALL_LIBDIR "lib")
set(CMAKE_INSTALL_INCLUDEDIR "include")

add_subdirectory(${SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR}/build-openblas)

# Keep the upstream library name (libopenblas.so) and point the exported
# INTERFACE_INCLUDE_DIRECTORIES at the directory OpenBLAS installs its headers
# to (include/openblas).
set_target_properties(openblas_shared PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/openblas>
)

# The OpenBLAS unit-test targets do not build with our setup.
set_target_properties(openblas_utest PROPERTIES EXCLUDE_FROM_ALL TRUE)
set_target_properties(openblas_utest_ext PROPERTIES EXCLUDE_FROM_ALL TRUE)

# Publish a "cblas" alias package that delegates to OpenBLAS::OpenBLAS.
configure_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/cblas-config.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/cblas-config.cmake
  @ONLY
)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/cblas-config.cmake" DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/OpenBLAS)
