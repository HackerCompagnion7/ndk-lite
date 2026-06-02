#!/data/data/com.termux/files/usr/bin/bash
# ============================================================================
# NDK Lite — Main Build Command
# Copyright (c) 2024-2026 Project Tomorrow Inc.
# Licensed under the Apache License, Version 2.0
# ============================================================================
#
# ndk-lite-build — Compiles Android native projects on ARM64 via Termux
#
# Usage:
#   ndk-lite-build [OPTIONS] [PROJECT_DIR]
#
# Options:
#   --type=static|shared   Library type (default: shared)
#   --api=N                Android API level (default: 26)
#   --stl=c++_static|c++_shared  C++ STL type (default: c++_static)
#   --release              Build in Release mode
#   --debug                Build in Debug mode
#   --clean                Clean before building
#   --verbose              Verbose output
#   --gen=make|ninja       Build system generator (default: ninja)
#   -jN                    Parallel jobs (default: nproc)
#   --output=DIR           Output directory
# ============================================================================

set -euo pipefail

NDK_LITE_VERSION="1.0.0"

# --- Colors for output -------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- Default configuration ---------------------------------------------------
LIB_TYPE="shared"
API_LEVEL=26
STL_TYPE="c++_static"
BUILD_TYPE="Release"
CLEAN_BUILD=false
VERBOSE=false
GENERATOR="Ninja"
JOBS=$(nproc 2>/dev/null || echo 4)
PROJECT_DIR=""
OUTPUT_DIR=""
EXTRA_CMAKE_ARGS=()

# --- Parse arguments ---------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --type=*)
            LIB_TYPE="${1#*=}"
            shift
            ;;
        --api=*)
            API_LEVEL="${1#*=}"
            shift
            ;;
        --stl=*)
            STL_TYPE="${1#*=}"
            shift
            ;;
        --release)
            BUILD_TYPE="Release"
            shift
            ;;
        --debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --gen=*)
            GENERATOR="${1#*=}"
            shift
            ;;
        -j*)
            JOBS="${1#-j}"
            shift
            ;;
        --output=*)
            OUTPUT_DIR="${1#*=}"
            shift
            ;;
        --help|-h)
            echo "ndk-lite-build v${NDK_LITE_VERSION} — Android ARM64 Native Builder"
            echo ""
            echo "Usage: ndk-lite-build [OPTIONS] [PROJECT_DIR]"
            echo ""
            echo "Options:"
            echo "  --type=static|shared   Library type (default: shared)"
            echo "  --api=N                Android API level (default: 26)"
            echo "  --stl=c++_static|c++_shared  C++ STL (default: c++_static)"
            echo "  --release              Release build (default)"
            echo "  --debug                Debug build"
            echo "  --clean                Clean before building"
            echo "  --verbose              Verbose output"
            echo "  --gen=make|ninja       Generator (default: ninja)"
            echo "  -jN                    Parallel jobs (default: nproc)"
            echo "  --output=DIR           Output directory"
            echo ""
            echo "Examples:"
            echo "  ndk-lite-build ."
            echo "  ndk-lite-build --type=static --api=28 my-project/"
            echo "  ndk-lite-build --clean --debug ."
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            if [[ -z "${PROJECT_DIR}" ]]; then
                PROJECT_DIR="$1"
            else
                EXTRA_CMAKE_ARGS+=("$1")
            fi
            shift
            ;;
    esac
done

# --- Resolve project directory -----------------------------------------------
if [[ -z "${PROJECT_DIR}" ]]; then
    PROJECT_DIR="$(pwd)"
fi

PROJECT_DIR="$(cd "${PROJECT_DIR}" && pwd)"

if [[ ! -d "${PROJECT_DIR}" ]]; then
    echo -e "${RED}[NDK Lite] ERROR: Project directory not found: ${PROJECT_DIR}${NC}" >&2
    exit 1
fi

# --- Resolve NDK Lite installation path --------------------------------------
if [[ -n "${NDK_LITE_HOME:-}" ]]; then
    NDK_LITE_DIR="${NDK_LITE_HOME}"
else
    SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
    SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
    NDK_LITE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
fi

TOOLCHAIN_FILE="${NDK_LITE_DIR}/cmake/android-arm64-v8a.cmake"

if [[ ! -f "${TOOLCHAIN_FILE}" ]]; then
    echo -e "${RED}[NDK Lite] ERROR: Toolchain file not found: ${TOOLCHAIN_FILE}${NC}" >&2
    echo -e "${YELLOW}[NDK Lite] Run: ndk-lite-setup${NC}" >&2
    exit 1
fi

# --- Verify dependencies -----------------------------------------------------
for cmd in cmake clang clang++ llvm-ar ninja; do
    if ! command -v "${cmd}" &>/dev/null; then
        echo -e "${RED}[NDK Lite] ERROR: ${cmd} not found in PATH${NC}" >&2
        echo -e "${YELLOW}[NDK Lite] Install with: pkg install clang cmake ninja${NC}" >&2
        exit 1
    fi
done

# --- Setup build directory ---------------------------------------------------
BUILD_DIR="${PROJECT_DIR}/.ndk-lite-build"

if [[ "${CLEAN_BUILD}" == true ]]; then
    echo -e "${CYAN}[NDK Lite] Cleaning build directory...${NC}"
    rm -rf "${BUILD_DIR}"
fi

mkdir -p "${BUILD_DIR}"

# --- Banner ------------------------------------------------------------------
echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║            NDK Lite v${NDK_LITE_VERSION} — Build              ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Project:${NC}    ${PROJECT_DIR}"
echo -e "  ${BOLD}ABI:${NC}        arm64-v8a"
echo -e "  ${BOLD}API:${NC}        ${API_LEVEL}"
echo -e "  ${BOLD}STL:${NC}        ${STL_TYPE}"
echo -e "  ${BOLD}Type:${NC}       ${LIB_TYPE}"
echo -e "  ${BOLD}Build:${NC}      ${BUILD_TYPE}"
echo -e "  ${BOLD}Generator:${NC}  ${GENERATOR}"
echo -e "  ${BOLD}Jobs:${NC}       ${JOBS}"
echo -e "  ${BOLD}Toolchain:${NC}  ${TOOLCHAIN_FILE}"
echo ""

# --- Step 1: CMake Configure -------------------------------------------------
echo -e "${CYAN}[1/3] Configuring CMake...${NC}"

CMAKE_ARGS=(
    -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAIN_FILE}"
    -DANDROID_ABI=arm64-v8a
    -DANDROID_PLATFORM="${API_LEVEL}"
    -DANDROID_STL="${STL_TYPE}"
    -DCMAKE_BUILD_TYPE="${BUILD_TYPE}"
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
)

# Set generator
case "${GENERATOR}" in
    ninja|Ninja)
        CMAKE_ARGS+=(-G Ninja)
        BUILD_CMD="ninja"
        ;;
    make|Make|Makefile)
        CMAKE_ARGS+=(-G "Unix Makefiles")
        BUILD_CMD="make"
        ;;
    *)
        echo -e "${RED}[NDK Lite] ERROR: Unknown generator: ${GENERATOR}${NC}" >&2
        exit 1
        ;;
esac

# Library type hints via CMake variable
if [[ "${LIB_TYPE}" == "static" ]]; then
    CMAKE_ARGS+=(-DBUILD_SHARED_LIBS=OFF)
else
    CMAKE_ARGS+=(-DBUILD_SHARED_LIBS=ON)
fi

# Output directory
if [[ -n "${OUTPUT_DIR}" ]]; then
    CMAKE_ARGS+=(
        -DCMAKE_LIBRARY_OUTPUT_DIRECTORY="${OUTPUT_DIR}"
        -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY="${OUTPUT_DIR}"
    )
fi

# Verbose mode
if [[ "${VERBOSE}" == true ]]; then
    CMAKE_ARGS+=(-DCMAKE_VERBOSE_MAKEFILE=ON)
fi

# Add extra cmake args
CMAKE_ARGS+=("${EXTRA_CMAKE_ARGS[@]}")

# Source directory
CMAKE_ARGS+=("${PROJECT_DIR}")

# Execute CMake
if ! cmake -B "${BUILD_DIR}" "${CMAKE_ARGS[@]}"; then
    echo -e "${RED}[NDK Lite] CMake configuration FAILED${NC}" >&2
    exit 1
fi

echo -e "${GREEN}[1/3] CMake configuration complete ✓${NC}"

# --- Step 2: Build -----------------------------------------------------------
echo -e "${CYAN}[2/3] Compiling with ${JOBS} parallel job(s)...${NC}"

BUILD_EXEC_ARGS=()
if [[ "${BUILD_CMD}" == "ninja" ]]; then
    BUILD_EXEC_ARGS=(-j "${JOBS}")
    if [[ "${VERBOSE}" == true ]]; then
        BUILD_EXEC_ARGS+=(-v)
    fi
elif [[ "${BUILD_CMD}" == "make" ]]; then
    BUILD_EXEC_ARGS=(-j"${JOBS}")
fi

if ! "${BUILD_CMD}" -C "${BUILD_DIR}" "${BUILD_EXEC_ARGS[@]}"; then
    echo -e "${RED}[NDK Lite] Build FAILED${NC}" >&2
    exit 1
fi

echo -e "${GREEN}[2/3] Compilation complete ✓${NC}"

# --- Step 3: Collect output --------------------------------------------------
echo -e "${CYAN}[3/3] Collecting artifacts...${NC}"

FINAL_OUTPUT="${OUTPUT_DIR:-${PROJECT_DIR}/build-output}"
mkdir -p "${FINAL_OUTPUT}"

# Find and copy built artifacts
ARTIFACT_COUNT=0
for ext in .so .a; do
    while IFS= read -r -d '' artifact; do
        cp -v "${artifact}" "${FINAL_OUTPUT}/"
        ((ARTIFACT_COUNT++)) || true
    done < <(find "${BUILD_DIR}" -name "*${ext}" -type f -print0 2>/dev/null)
done

# --- Final summary -----------------------------------------------------------
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║            BUILD SUCCESSFUL                      ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Artifacts:${NC}   ${ARTIFACT_COUNT} file(s)"
echo -e "  ${BOLD}Output:${NC}     ${FINAL_OUTPUT}"

if [[ ${ARTIFACT_COUNT} -gt 0 ]]; then
    echo ""
    echo -e "  ${BOLD}Files:${NC}"
    for f in "${FINAL_OUTPUT}"/*.so "${FINAL_OUTPUT}"/*.a; do
        if [[ -f "$f" ]]; then
            SIZE=$(du -h "$f" | cut -f1)
            echo -e "    ${GREEN}●${NC} $(basename "$f") (${SIZE})"
        fi
    done
fi

echo ""
echo -e "${YELLOW}[NDK Lite] Build completed at $(date '+%Y-%m-%d %H:%M:%S')${NC}"
