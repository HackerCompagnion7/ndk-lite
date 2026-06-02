#!/data/data/com.termux/files/usr/bin/bash
# ============================================================================
# NDK Lite — Clang Wrapper for Android ARM64 Cross-Compilation
# Copyright (c) 2024-2026 Project Tomorrow Inc.
# Licensed under the Apache License, Version 2.0
# ============================================================================
#
# This script wraps the Termux clang binary and automatically injects
# Android ARM64 target flags. It allows using clang directly as if it
# were the Android NDK compiler.
#
# Usage:
#   ndk-lite-cc <source.c> -o <output>
#   ndk-lite-cc --version
# ============================================================================

set -euo pipefail

# --- Configuration -----------------------------------------------------------
NDK_LITE_VERSION="1.0.0"
NDK_LITE_TARGET_TRIPLE="aarch64-linux-android"
NDK_LITE_DEFAULT_API=26

# --- Resolve Termux prefix ---------------------------------------------------
if [[ -n "${TERMUX_PREFIX:-}" ]]; then
    TERMUX_PREFIX="${TERMUX_PREFIX}"
elif [[ -n "${PREFIX:-}" ]]; then
    TERMUX_PREFIX="${PREFIX}"
else
    TERMUX_PREFIX="/data/data/com.termux/files/usr"
fi

CLANG_BIN="${TERMUX_PREFIX}/bin/clang"

# --- Verify clang exists -----------------------------------------------------
if [[ ! -x "${CLANG_BIN}" ]]; then
    echo "[NDK Lite] ERROR: clang not found at ${CLANG_BIN}" >&2
    echo "[NDK Lite] Install with: pkg install clang" >&2
    exit 1
fi

# --- Resolve NDK Lite sysroot ------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NDK_LITE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
NDK_LITE_SYSROOT="${NDK_LITE_DIR}/sysroot"

if [[ ! -d "${NDK_LITE_SYSROOT}" ]]; then
    echo "[NDK Lite] WARNING: sysroot not found at ${NDK_LITE_SYSROOT}" >&2
    echo "[NDK Lite] Run: ndk-lite-setup" >&2
fi

# --- Parse arguments ---------------------------------------------------------
API_LEVEL="${NDK_LITE_DEFAULT_API}"
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ndk-lite-api=*)
            API_LEVEL="${1#*=}"
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

# --- Build compiler flags ----------------------------------------------------
TARGET_FLAG="--target=${NDK_LITE_TARGET_TRIPLE}${API_LEVEL}"
SYSROOT_FLAG="--sysroot=${NDK_LITE_SYSROOT}"

NDK_LITE_FLAGS=(
    "${TARGET_FLAG}"
    "${SYSROOT_FLAG}"
    -fPIC
    -fstack-protector-strong
    -DANDROID
    -D__ANDROID__
    -DNDK_LITE
)

# --- Execute clang with injected flags ---------------------------------------
exec "${CLANG_BIN}" "${NDK_LITE_FLAGS[@]}" "${EXTRA_ARGS[@]}"
