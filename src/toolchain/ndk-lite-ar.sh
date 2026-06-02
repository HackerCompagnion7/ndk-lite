#!/data/data/com.termux/files/usr/bin/bash
# ============================================================================
# NDK Lite — llvm-ar Wrapper
# Copyright (c) 2024-2026 Project Tomorrow Inc.
# Licensed under the Apache License, Version 2.0
# ============================================================================
#
# Wraps llvm-ar for creating and managing static library archives (.a)
# compatible with the Android ARM64 target.
#
# Usage:
#   ndk-lite-ar rcs libfoo.a obj1.o obj2.o
# ============================================================================

set -euo pipefail

if [[ -n "${TERMUX_PREFIX:-}" ]]; then
    TERMUX_PREFIX="${TERMUX_PREFIX}"
elif [[ -n "${PREFIX:-}" ]]; then
    TERMUX_PREFIX="${PREFIX}"
else
    TERMUX_PREFIX="/data/data/com.termux/files/usr"
fi

AR_BIN="${TERMUX_PREFIX}/bin/llvm-ar"

if [[ ! -x "${AR_BIN}" ]]; then
    echo "[NDK Lite] ERROR: llvm-ar not found at ${AR_BIN}" >&2
    echo "[NDK Lite] Install with: pkg install llvm" >&2
    exit 1
fi

exec "${AR_BIN}" "$@"
