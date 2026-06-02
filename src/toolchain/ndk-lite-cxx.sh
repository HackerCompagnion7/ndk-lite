#!/data/data/com.termux/files/usr/bin/bash
# ============================================================================
# NDK Lite — Clang++ Wrapper for Android ARM64 Cross-Compilation
# Copyright (c) 2024-2026 Project Tomorrow Inc.
# Licensed under the Apache License, Version 2.0
# ============================================================================
#
# C++ counterpart of ndk-lite-cc. Wraps clang++ with Android ARM64
# target flags and C++ standard library configuration.
#
# Usage:
#   ndk-lite-cxx <source.cpp> -o <output>
# ============================================================================

set -euo pipefail

NDK_LITE_VERSION="1.0.0"
NDK_LITE_TARGET_TRIPLE="aarch64-linux-android"
NDK_LITE_DEFAULT_API=26

if [[ -n "${TERMUX_PREFIX:-}" ]]; then
    TERMUX_PREFIX="${TERMUX_PREFIX}"
elif [[ -n "${PREFIX:-}" ]]; then
    TERMUX_PREFIX="${PREFIX}"
else
    TERMUX_PREFIX="/data/data/com.termux/files/usr"
fi

CLANGXX_BIN="${TERMUX_PREFIX}/bin/clang++"

if [[ ! -x "${CLANGXX_BIN}" ]]; then
    echo "[NDK Lite] ERROR: clang++ not found at ${CLANGXX_BIN}" >&2
    echo "[NDK Lite] Install with: pkg install clang" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NDK_LITE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
NDK_LITE_SYSROOT="${NDK_LITE_DIR}/sysroot"

API_LEVEL="${NDK_LITE_DEFAULT_API}"
STL_TYPE="c++_static"
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ndk-lite-api=*)
            API_LEVEL="${1#*=}"
            shift
            ;;
        --ndk-lite-stl=*)
            STL_TYPE="${1#*=}"
            shift
            ;;
        --ndk-lite-version)
            echo "NDK Lite v${NDK_LITE_VERSION}"
            exit 0
            ;;
        --ndk-lite-sysroot=*)
            NDK_LITE_SYSROOT="${1#*=}"
            shift
            ;;
        *)
            EXTRA_ARGS+=("$1")
            shift
            ;;
    esac
done

TARGET_FLAG="--target=${NDK_LITE_TARGET_TRIPLE}${API_LEVEL}"
SYSROOT_FLAG="--sysroot=${NDK_LITE_SYSROOT}"

NDK_LITE_FLAGS=(
    "${TARGET_FLAG}"
    "${SYSROOT_FLAG}"
    -fPIC
    -fstack-protector-strong
    -fno-rtti
    -fno-exceptions
    -DANDROID
    -D__ANDROID__
    -DNDK_LITE
)

if [[ "${STL_TYPE}" == "c++_static" ]]; then
    NDK_LITE_FLAGS+=("-static-libstdc++")
elif [[ "${STL_TYPE}" == "c++_shared" ]]; then
    NDK_LITE_FLAGS+=("-DANDROID_STL=c++_shared")
fi

exec "${CLANGXX_BIN}" "${NDK_LITE_FLAGS[@]}" "${EXTRA_ARGS[@]}"
