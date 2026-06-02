#!/data/data/com.termux/files/usr/bin/bash
# ============================================================================
# NDK Lite — Setup & Installation Command
# Copyright (c) 2024-2026 Project Tomorrow Inc.
# Licensed under the Apache License, Version 2.0
# ============================================================================
#
# ndk-lite-setup — Initializes NDK Lite environment on Termux
#
# This script:
#   1. Verifies Termux dependencies are installed
#   2. Generates the Android sysroot
#   3. Installs wrapper scripts to Termux bin
#   4. Configures environment variables
#
# Usage:
#   ndk-lite-setup [--api=26] [--ndk-path=/path/to/ndk]
# ============================================================================

set -euo pipefail

NDK_LITE_VERSION="1.0.0"

# --- Colors ------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

API_LEVEL=26
NDK_PATH=""
TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
INSTALL_BIN="${TERMUX_PREFIX}/bin"
FORCE=false

# --- Parse arguments ---------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --api=*)       API_LEVEL="${1#*=}"; shift ;;
        --ndk-path=*)  NDK_PATH="${1#*=}"; shift ;;
        --force)       FORCE=true; shift ;;
        --help|-h)
            echo "ndk-lite-setup v${NDK_LITE_VERSION}"
            echo "Usage: ndk-lite-setup [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --api=N          Android API level (default: 26)"
            echo "  --ndk-path=PATH  Path to Android NDK for sysroot extraction"
            echo "  --force          Force reinstallation"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# --- Banner ------------------------------------------------------------------
echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║         NDK Lite v${NDK_LITE_VERSION} — Setup                ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# --- Step 1: Check Termux environment ----------------------------------------
echo -e "${CYAN}[1/5] Checking Termux environment...${NC}"

if [[ ! -d "${TERMUX_PREFIX}" ]]; then
    echo -e "${RED}ERROR: Not running in Termux environment${NC}" >&2
    exit 1
fi

echo -e "  ${GREEN}✓${NC} Termux detected: ${TERMUX_PREFIX}"

# --- Step 2: Install dependencies --------------------------------------------
echo -e "${CYAN}[2/5] Checking dependencies...${NC}"

DEPS=(clang cmake ninja llvm git)
MISSING=()

for dep in "${DEPS[@]}"; do
    if command -v "${dep}" &>/dev/null; then
        VERSION=$("${dep}" --version 2>&1 | head -1)
        echo -e "  ${GREEN}✓${NC} ${dep}: ${VERSION}"
    else
        echo -e "  ${YELLOW}✗${NC} ${dep}: not found"
        MISSING+=("${dep}")
    fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}Installing missing packages: ${MISSING[*]}${NC}"
    pkg install -y "${MISSING[@]}" 2>/dev/null || {
        echo -e "${RED}Failed to install packages. Run manually:${NC}" >&2
        echo -e "  pkg install ${MISSING[*]}" >&2
        exit 1
    }
    echo -e "${GREEN}Dependencies installed ✓${NC}"
fi

# --- Step 3: Resolve NDK Lite home -------------------------------------------
echo -e "${CYAN}[3/5] Configuring NDK Lite home...${NC}"

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
NDK_LITE_HOME="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo -e "  NDK_LITE_HOME = ${NDK_LITE_HOME}"

# --- Step 4: Generate sysroot ------------------------------------------------
echo -e "${CYAN}[4/5] Generating Android sysroot...${NC}"

SETUP_SYSROOT="${NDK_LITE_HOME}/src/sysroot/generate_sysroot.sh"

if [[ -f "${SETUP_SYSROOT}" ]]; then
    SYSROOT_ARGS="--api=${API_LEVEL}"
    if [[ -n "${NDK_PATH}" ]]; then
        SYSROOT_ARGS+=" --ndk-path=${NDK_PATH}"
    fi

    if bash "${SETUP_SYSROOT}" ${SYSROOT_ARGS}; then
        echo -e "${GREEN}Sysroot generated ✓${NC}"
    else
        echo -e "${RED}Sysroot generation failed${NC}" >&2
        exit 1
    fi
else
    echo -e "${YELLOW}WARNING: Sysroot generator not found. Run manually later.${NC}" >&2
fi

# --- Step 5: Install scripts to PATH -----------------------------------------
echo -e "${CYAN}[5/5] Installing commands to PATH...${NC}"

SCRIPTS_DIR="${NDK_LITE_HOME}/scripts"
TOOLCHAIN_DIR="${NDK_LITE_HOME}/src/toolchain"

# Install main commands
COMMANDS=()
while IFS= read -r -d '' script; do
    CMD_NAME="$(basename "${script}" .sh)"
    # Convert ndk-lite-X.sh to ndk-lite-X
    TARGET="${INSTALL_BIN}/${CMD_NAME}"

    if [[ -f "${TARGET}" ]] && [[ "${FORCE}" != true ]]; then
        echo -e "  ${YELLOW}⊘${NC} ${CMD_NAME} (already exists, use --force)"
    else
        cp "${script}" "${TARGET}"
        chmod +x "${TARGET}"
        # Replace placeholder paths inside the script
        if command -v sed &>/dev/null; then
            sed -i "s|__NDK_LITE_HOME__|${NDK_LITE_HOME}|g" "${TARGET}" 2>/dev/null || true
        fi
        echo -e "  ${GREEN}✓${NC} ${CMD_NAME} → ${TARGET}"
        COMMANDS+=("${CMD_NAME}")
    fi
done < <(find "${SCRIPTS_DIR}" -name "*.sh" -type f -print0 2>/dev/null)

# Install toolchain wrappers
while IFS= read -r -d '' script; do
    CMD_NAME="$(basename "${script}" .sh)"
    TARGET="${INSTALL_BIN}/${CMD_NAME}"

    if [[ -f "${TARGET}" ]] && [[ "${FORCE}" != true ]]; then
        echo -e "  ${YELLOW}⊘${NC} ${CMD_NAME} (already exists)"
    else
        cp "${script}" "${TARGET}"
        chmod +x "${TARGET}"
        echo -e "  ${GREEN}✓${NC} ${CMD_NAME} → ${TARGET}"
        COMMANDS+=("${CMD_NAME}")
    fi
done < <(find "${TOOLCHAIN_DIR}" -name "*.sh" -type f -print0 2>/dev/null)

# --- Environment configuration -----------------------------------------------
SHELL_RC="${HOME}/.bashrc"
ENV_LINE="export NDK_LITE_HOME=\"${NDK_LITE_HOME}\""

if ! grep -q "NDK_LITE_HOME" "${SHELL_RC}" 2>/dev/null; then
    echo "" >> "${SHELL_RC}"
    echo "# NDK Lite" >> "${SHELL_RC}"
    echo "${ENV_LINE}" >> "${SHELL_RC}"
    echo -e "  ${GREEN}✓${NC} NDK_LITE_HOME added to ~/.bashrc"
else
    echo -e "  ${YELLOW}⊘${NC} NDK_LITE_HOME already in ~/.bashrc"
fi

export NDK_LITE_HOME="${NDK_LITE_HOME}"

# --- Final summary -----------------------------------------------------------
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║         NDK Lite Setup Complete!                 ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Home:${NC}       ${NDK_LITE_HOME}"
echo -e "  ${BOLD}Sysroot:${NC}    ${NDK_LITE_HOME}/sysroot"
echo -e "  ${BOLD}API:${NC}        ${API_LEVEL}"
echo -e "  ${BOLD}Commands:${NC}   ${#COMMANDS[@]} installed"
echo ""
echo -e "  ${BOLD}${CYAN}Available Commands:${NC}"
echo "    ndk-lite-new <type> <name>     Create a new project"
echo "    ndk-lite-build [dir]           Build a project"
echo "    ndk-lite-cc <file.c>           Compile C file"
echo "    ndk-lite-cxx <file.cpp>        Compile C++ file"
echo "    ndk-lite-ld <options>          Link objects"
echo "    ndk-lite-ar rcs <lib.a> <.o>   Create static library"
echo ""
echo -e "  ${BOLD}${YELLOW}Quick Start:${NC}"
echo "    ndk-lite-new cpp mylib"
echo "    cd mylib"
echo "    ndk-lite-build ."
echo ""
