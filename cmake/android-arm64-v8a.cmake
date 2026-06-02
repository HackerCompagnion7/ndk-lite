# ============================================================================
# NDK Lite — Android ARM64 Toolchain File for CMake
# Copyright (c) 2024-2026 Project Tomorrow Inc.
# Licensed under the Apache License, Version 2.0
# ============================================================================
#
# Purpose:
#   Provides a complete CMake toolchain configuration for cross-compiling
#   Android native libraries on ARM64 devices running Termux.
#
#   This file replaces the need for the official Android NDK toolchain,
#   using the native Termux LLVM/Clang ARM64 toolchain with Android
#   sysroot headers and libraries.
#
# Usage:
#   cmake -DCMAKE_TOOLCHAIN_FILE=<path>/android-arm64-v8a.cmake ..
#   Or via ndk-lite-build (recommended)
# ============================================================================

# Guard against multiple inclusion
if(DEFINED NDK_LITE_TOOLCHAIN_LOADED)
  return()
endif()
set(NDK_LITE_TOOLCHAIN_LOADED TRUE)

# ---------------------------------------------------------------------------
# 1. Target Architecture Configuration
# ---------------------------------------------------------------------------
set(NDK_LITE_TARGET_ARCH       "arm64")
set(NDK_LITE_TARGET_ABI        "arm64-v8a")
set(NDK_LITE_TARGET_TRIPLE     "aarch64-linux-android")
set(NDK_LITE_HOST_TAG          "linux-aarch64")

# ---------------------------------------------------------------------------
# 2. User-Configurable Variables (override with -D flags)
# ---------------------------------------------------------------------------
if(NOT DEFINED ANDROID_ABI)
  set(ANDROID_ABI "${NDK_LITE_TARGET_ABI}")
endif()

if(NOT DEFINED ANDROID_PLATFORM)
  set(ANDROID_PLATFORM 26)
endif()

if(NOT DEFINED ANDROID_STL)
  set(ANDROID_STL "c++_static")
endif()

if(NOT DEFINED NDK_LITE_SYSROOT)
  # Default: look relative to this toolchain file
  get_filename_component(NDK_LITE_DIR "${CMAKE_CURRENT_LIST_DIR}" DIRECTORY)
  set(NDK_LITE_SYSROOT "${NDK_LITE_DIR}/sysroot")
endif()

# ---------------------------------------------------------------------------
# 3. Compiler Identification
# ---------------------------------------------------------------------------
set(CMAKE_SYSTEM_NAME Android)
set(CMAKE_SYSTEM_VERSION ${ANDROID_PLATFORM})
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_ANDROID_ARCH_ABI ${ANDROID_ABI})

# Tell CMake we are cross-compiling for Android
set(ANDROID TRUE)
set(CMAKE_CROSSCOMPILING TRUE)

# ---------------------------------------------------------------------------
# 4. Locate Termux LLVM/Clang Toolchain
# ---------------------------------------------------------------------------
# Termux installs clang to /data/data/com.termux/files/usr/bin/
if(NOT DEFINED TERMUX_PREFIX)
  if(DEFINED ENV{PREFIX})
    set(TERMUX_PREFIX "$ENV{PREFIX}")
  elseif(DEFINED ENV{TERMUX_PREFIX})
    set(TERMUX_PREFIX "$ENV{TERMUX_PREFIX}")
  else()
    set(TERMUX_PREFIX "/data/data/com.termux/files/usr")
  endif()
endif()

set(TERMUX_BIN "${TERMUX_PREFIX}/bin")

# Verify clang exists
if(NOT EXISTS "${TERMUX_BIN}/clang")
  message(FATAL_ERROR
    "[NDK Lite] clang not found at ${TERMUX_BIN}/clang. "
    "Install it with: pkg install clang"
  )
endif()

# ---------------------------------------------------------------------------
# 5. Compiler Flags
# ---------------------------------------------------------------------------
set(NDK_LITE_TARGET_FLAG "--target=${NDK_LITE_TARGET_TRIPLE}${ANDROID_PLATFORM}")

# Common flags for both C and C++
set(NDK_LITE_COMMON_FLAGS
  ${NDK_LITE_TARGET_FLAG}
  -fPIC
  -fstack-protector-strong
  -fno-strict-aliasing
  -ffunction-sections
  -fdata-sections
  -funwind-tables
  -fno-exceptions
  -DANDROID
  -D__ANDROID__
  -DNDK_LITE
)

# C-specific flags
set(NDK_LITE_C_FLAGS
  ${NDK_LITE_COMMON_FLAGS}
)

# C++-specific flags
set(NDK_LITE_CXX_FLAGS
  ${NDK_LITE_COMMON_FLAGS}
  -fno-rtti
)

if(ANDROID_STL STREQUAL "c++_static")
  list(APPEND NDK_LITE_CXX_FLAGS -DANDROID_STL=c++_static)
elseif(ANDROID_STL STREQUAL "c++_shared")
  list(APPEND NDK_LITE_CXX_FLAGS -DANDROID_STL=c++_shared)
endif()

# Linker flags
set(NDK_LITE_LINKER_FLAGS
  --target=${NDK_LITE_TARGET_TRIPLE}${ANDROID_PLATFORM}
  -Wl,--build-id=sha1
  -Wl,--no-rosegment
  -Wl,--no-undefined
  -Wl,--gc-sections
  -Wl,--as-needed
  -landroid
  -llog
)

# ---------------------------------------------------------------------------
# 6. Set CMake Compiler Variables
# ---------------------------------------------------------------------------
set(CMAKE_C_COMPILER   "${TERMUX_BIN}/clang"  CACHE PATH "C compiler" FORCE)
set(CMAKE_CXX_COMPILER "${TERMUX_BIN}/clang++" CACHE PATH "C++ compiler" FORCE)

# Archiver and ranlib from LLVM
set(CMAKE_AR           "${TERMUX_BIN}/llvm-ar"    CACHE PATH "Archiver" FORCE)
set(CMAKE_RANLIB       "${TERMUX_BIN}/llvm-ranlib" CACHE PATH "Ranlib" FORCE)

# Linker: use LLD via clang driver
set(CMAKE_LINKER       "${TERMUX_BIN}/clang++"     CACHE PATH "Linker" FORCE)

# Other tools
set(CMAKE_OBJCOPY      "${TERMUX_BIN}/llvm-objcopy"  CACHE PATH "Objcopy" FORCE)
set(CMAKE_OBJDUMP      "${TERMUX_BIN}/llvm-objdump"  CACHE PATH "Objdump" FORCE)
set(CMAKE_STRIP        "${TERMUX_BIN}/llvm-strip"    CACHE PATH "Strip" FORCE)
set(CMAKE_NM           "${TERMUX_BIN}/llvm-nm"       CACHE PATH "NM" FORCE)
set(CMAKE_READOBJ      "${TERMUX_BIN}/llvm-readobj"  CACHE PATH "Readobj" FORCE)

# ---------------------------------------------------------------------------
# 7. Sysroot Configuration
# ---------------------------------------------------------------------------
set(CMAKE_SYSROOT "${NDK_LITE_SYSROOT}" CACHE PATH "Android sysroot" FORCE)

# Include directories
include_directories(SYSTEM
  "${NDK_LITE_SYSROOT}/usr/include"
  "${NDK_LITE_SYSROOT}/usr/include/aarch64-linux-android"
)

# Library directories
link_directories(
  "${NDK_LITE_SYSROOT}/usr/lib/aarch64-linux-android/${ANDROID_PLATFORM}"
  "${NDK_LITE_SYSROOT}/usr/lib/aarch64-linux-android"
)

# ---------------------------------------------------------------------------
# 8. Apply Flags to CMake
# ---------------------------------------------------------------------------
string(REPLACE ";" " " NDK_LITE_C_FLAGS_STR "${NDK_LITE_C_FLAGS}")
string(REPLACE ";" " " NDK_LITE_CXX_FLAGS_STR "${NDK_LITE_CXX_FLAGS}")
string(REPLACE ";" " " NDK_LITE_LINKER_FLAGS_STR "${NDK_LITE_LINKER_FLAGS}")

set(CMAKE_C_FLAGS           "${CMAKE_C_FLAGS} ${NDK_LITE_C_FLAGS_STR}" CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS         "${CMAKE_CXX_FLAGS} ${NDK_LITE_CXX_FLAGS_STR}" CACHE STRING "" FORCE)
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${NDK_LITE_LINKER_FLAGS_STR}" CACHE STRING "" FORCE)
set(CMAKE_EXE_LINKER_FLAGS    "${CMAKE_EXE_LINKER_FLAGS} ${NDK_LITE_LINKER_FLAGS_STR}" CACHE STRING "" FORCE)
set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} ${NDK_LITE_LINKER_FLAGS_STR}" CACHE STRING "" FORCE)

# ---------------------------------------------------------------------------
# 9. Build Type Defaults
# ---------------------------------------------------------------------------
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type" FORCE)
endif()

# ---------------------------------------------------------------------------
# 10. Output Artifacts Configuration
# ---------------------------------------------------------------------------
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/libs/${ANDROID_ABI}" CACHE PATH "" FORCE)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/libs/${ANDROID_ABI}" CACHE PATH "" FORCE)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" CACHE PATH "" FORCE)

# ---------------------------------------------------------------------------
# 11. NDK Lite Metadata (for consuming scripts)
# ---------------------------------------------------------------------------
set(NDK_LITE_VERSION "1.0.0")
set(NDK_LITE_ENABLED TRUE)

message(STATUS "")
message(STATUS "============================================")
message(STATUS "  NDK Lite v${NDK_LITE_VERSION} — Toolchain Active")
message(STATUS "============================================")
message(STATUS "  Target:   ${NDK_LITE_TARGET_TRIPLE}${ANDROID_PLATFORM}")
message(STATUS "  ABI:      ${ANDROID_ABI}")
message(STATUS "  STL:      ${ANDROID_STL}")
message(STATUS "  Sysroot:  ${NDK_LITE_SYSROOT}")
message(STATUS "  Clang:    ${TERMUX_BIN}/clang")
message(STATUS "  Build:    ${CMAKE_BUILD_TYPE}")
message(STATUS "============================================")
message(STATUS "")
