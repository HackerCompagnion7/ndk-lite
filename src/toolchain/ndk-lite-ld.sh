#!/data/data/com.termux/files/usr/bin/bash
# ============================================================================
# NDK Lite — LLD Linker Wrapper for Android ARM64
# Copyright (c) 2024-2026 Project Tomorrow Inc.
# Licensed under the Apache License, Version 2.0
# ============================================================================
#
# Wraps the LLD linker (via clang driver) with Android-specific link flags.
# Produces ELF shared libraries (.so) and executables compatible with Android.
#
# Usage:
#   ndk-lite-ld -shared -o libfoo.so obj1.o obj2.o
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
    echo "[NDK Lite] ERROR: clang++ (linker driver) not found at ${CLANGXX_BIN}" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NDK_LITE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
NDK_LITE_SYSROOT="${NDK_LITE_DIR}/sysroot"

API_LEVEL="${NDK_LITE_DEFAULT_API}"
LINK_TYPE="shared"
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ndk-lite-api=*)
            API_LEVEL="${1#*=}"
            shift
            ;;
        -shared)
            LINK_TYPE="shared"
            EXTRA_ARGS+=("-shared")
            shift
            ;;
        -static)
            LINK_TYPE="static"
            EXTRA_ARGS+=("-static")
            shift
            ;;
        --ndk-lite-version)
            echo "NDK Lite Linker v${NDK_LITE_VERSION}"
            exit 0
            ;;
        *)
            EXTRA_ARGS+=("$1")
            shift
            ;;
    esac
done

TARGET_FLAG="--target=${NDK_LITE_TARGET_TRIPLE}${API_LEVEL}"
SYSROOT_FLAG="--sysroot=${NDK_LITE_SYSROOT}"

NDK_LITE_LINK_FLAGS=(
    "${TARGET_FLAG}"
    "${SYSROOT_FLAG}"
    -fuse-ld=lld
    -Wl,--build-id=sha1
    -Wl,--no-rosegment
    -Wl,--gc-sections
    -Wl,--as-needed
    -landroid
    -llog
)

if [[ "${LINK_TYPE}" == "shared" ]]; then
    NDK_LITE_LINK_FLAGS+=(
        -Wl,-soname,liboutput.so
        -Wl,--no-undefined
    )
fi

exec "${CLANGXX_BIN}" "${NDK_LITE_LINK_FLAGS[@]}" "${EXTRA_ARGS[@]}"
