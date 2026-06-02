# ============================================================================
# assimp_lite — Validation Test for NDK Lite
# Copyright (c) 2024-2026 Project Tomorrow Inc.
# Licensed under the Apache License, Version 2.0
# ============================================================================
#
# This is a minimal subset of the Assimp library structure to validate
# that NDK Lite can compile a real-world C++ project with CMake
# on Android ARM64 via Termux.
# ============================================================================

cmake_minimum_required(VERSION 3.22)

project(assimp_lite
    VERSION 1.0.0
    LANGUAGES CXX
)

# --- Options -----------------------------------------------------------------
option(BUILD_SHARED_LIBS "Build shared library" ON)
option(ASSIMP_LITE_BUILD_TESTS "Build test programs" OFF)

# --- Source files ------------------------------------------------------------
set(ASSIMP_LITE_SOURCES
    src/scene.cpp
    src/mesh.cpp
    src/material.cpp
    src/importer.cpp
    src/logger.cpp
    src/math/vec3.cpp
    src/math/mat4.cpp
    src/math/quaternion.cpp
    src/formats/obj_loader.cpp
    src/formats/stl_loader.cpp
)

set(ASSIMP_LITE_HEADERS
    include/assimp_lite/scene.h
    include/assimp_lite/mesh.h
    include/assimp_lite/material.h
    include/assimp_lite/importer.h
    include/assimp_lite/logger.h
    include/assimp_lite/config.h
    include/assimp_lite/math/vec3.h
    include/assimp_lite/math/mat4.h
    include/assimp_lite/math/quaternion.h
    include/assimp_lite/formats/obj_loader.h
    include/assimp_lite/formats/stl_loader.h
)

# --- Target definition -------------------------------------------------------
if(BUILD_SHARED_LIBS)
    add_library(${PROJECT_NAME} SHARED ${ASSIMP_LITE_SOURCES})
else()
    add_library(${PROJECT_NAME} STATIC ${ASSIMP_LITE_SOURCES})
endif()

# --- Include directories -----------------------------------------------------
target_include_directories(${PROJECT_NAME}
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# --- Compile features --------------------------------------------------------
target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_17)

# --- Compiler warnings -------------------------------------------------------
target_compile_options(${PROJECT_NAME} PRIVATE
    -Wall -Wextra -Wpedantic
    -Wno-unused-parameter
)

# --- Link libraries ----------------------------------------------------------
target_link_libraries(${PROJECT_NAME}
    PRIVATE
        log
)

# --- Test executable ---------------------------------------------------------
if(ASSIMP_LITE_BUILD_TESTS)
    add_executable(assimp_lite_test
        tests/test_main.cpp
    )
    target_link_libraries(assimp_lite_test
        PRIVATE
            ${PROJECT_NAME}
            log
    )
endif()
