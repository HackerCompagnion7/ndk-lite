#!/data/data/com.termux/files/usr/bin/bash
# ============================================================================
# NDK Lite — llvm-ranlib Wrapper
# Copyright (c) 2024-2026 Project Tomorrow Inc.
# Licensed under the Apache License, Version 2.0
# ============================================================================
#
# Wraps llvm-ranlib for generating index for static library archives.
#
# Usage:
#   ndk-lite-ranlib libfoo.a
# ============================================================================

set -euo pipefail

if [[ -n "${TERMUX_PREFIX:-}" ]]; then
    TERMUX_PREFIX="${TERMUX_PREFIX}"
elif [[ -n "${PREFIX:-}" ]]; then
    TERMUX_PREFIX="${PREFIX}"
else
    TERMUX_PREFIX="/data/data/com.termux/files/usr"
fi

RANLIB_BIN="${TERMUX_PREFIX}/bin/llvm-ranlib"

if [[ ! -x "${RANLIB_BIN}" ]]; then
    echo "[NDK Lite] ERROR: llvm-ranlib not found at ${RANLIB_BIN}" >&2
    echo "[NDK Lite] Install with: pkg install llvm" >&2
    exit 1
fi

exec "${RANLIB_BIN}" "$@"
