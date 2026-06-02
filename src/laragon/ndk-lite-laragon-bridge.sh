#!/data/data/com.termux/files/usr/bin/bash
# ============================================================================
# NDK Lite — Laragon OS Integration Bridge
# Copyright (c) 2024-2026 Project Tomorrow Inc.
# Licensed under the Apache License, Version 2.0
# ============================================================================
#
# This script provides the bridge between Laragon OS UI actions and NDK Lite
# CLI commands. Laragon OS calls these endpoints when the user interacts
# with the visual interface.
#
# Communication protocol: JSON on stdout
# Each command outputs a JSON response with:
#   { "status": "ok"|"error", "message": "...", "progress": 0-100, "data": {} }
# ============================================================================

set -euo pipefail

NDK_LITE_VERSION="1.0.0"
NDK_LITE_HOME="${NDK_LITE_HOME:-$HOME/ndk-lite}"

# --- Helper: JSON output -----------------------------------------------------
json_response() {
    local status="$1"
    local message="$2"
    local progress="${3:-0}"
    local data="${4:-{}}"

    printf '{"status":"%s","message":"%s","progress":%d,"data":%s}\n' \
        "${status}" "${message}" "${progress}" "${data}"
}

# --- Command: Create Project -------------------------------------------------
cmd_create_project() {
    local project_type="${1:-cpp}"
    local project_name="${2:-untitled}"

    json_response "ok" "Creating ${project_type} project: ${project_name}" 10

    if ! command -v ndk-lite-new &>/dev/null; then
        json_response "error" "ndk-lite-new not found. Run ndk-lite-setup first." 0
        return 1
    fi

    json_response "ok" "Generating project structure..." 30

    cd "${HOME}" || {
        json_response "error" "Cannot access home directory" 0
        return 1
    }

    if ndk-lite-new "${project_type}" "${project_name}" 2>&1; then
        json_response "ok" "Project ${project_name} created successfully" 100 \
            "{\"path\":\"${HOME}/${project_name}\",\"type\":\"${project_type}\"}"
    else
        json_response "error" "Failed to create project ${project_name}" 0
        return 1
    fi
}

# --- Command: Build Project --------------------------------------------------
cmd_build_project() {
    local project_path="${1:-.}"
    local build_type="${2:-release}"

    json_response "ok" "Starting build..." 5

    if [[ ! -d "${project_path}" ]]; then
        json_response "error" "Project directory not found: ${project_path}" 0
        return 1
    fi

    json_response "ok" "Configuring CMake..." 20

    local build_flag="--release"
    if [[ "${build_type}" == "debug" ]]; then
        build_flag="--debug"
    fi

    json_response "ok" "Compiling native code..." 50

    if ndk-lite-build ${build_flag} "${project_path}" 2>&1; then
        json_response "ok" "Build completed successfully" 100 \
            "{\"output\":\"${project_path}/build-output\"}"
    else
        json_response "error" "Build failed" 0
        return 1
    fi
}

# --- Command: Clean Project --------------------------------------------------
cmd_clean_project() {
    local project_path="${1:-.}"

    if [[ -d "${project_path}/.ndk-lite-build" ]]; then
        rm -rf "${project_path}/.ndk-lite-build"
        rm -rf "${project_path}/build-output"
        json_response "ok" "Project cleaned" 100
    else
        json_response "ok" "Nothing to clean" 100
    fi
}

# --- Command: Get Project Info -----------------------------------------------
cmd_project_info() {
    local project_path="${1:-.}"

    if [[ ! -f "${project_path}/ndk-lite.config" ]]; then
        json_response "error" "Not an NDK Lite project" 0
        return 1
    fi

    local name type version
    name=$(grep '^name' "${project_path}/ndk-lite.config" 2>/dev/null | cut -d= -f2 | tr -d ' ')
    type=$(grep '^type' "${project_path}/ndk-lite.config" 2>/dev/null | cut -d= -f2 | tr -d ' ')
    version=$(grep '^version' "${project_path}/ndk-lite.config" 2>/dev/null | cut -d= -f2 | tr -d ' ')

    json_response "ok" "Project info" 100 \
        "{\"name\":\"${name:-unknown}\",\"type\":\"${type:-unknown}\",\"version\":\"${version:-0.0.0}\"}"
}

# --- Command: List Templates -------------------------------------------------
cmd_list_templates() {
    json_response "ok" "Available templates" 100 \
        '{"templates":["cpp","c","jni","opengl"]}'
}

# --- Command: Check Environment ----------------------------------------------
cmd_check_env() {
    local ok=true
    local missing=()

    for cmd in clang clang++ cmake ninja llvm-ar; do
        if ! command -v "${cmd}" &>/dev/null; then
            ok=false
            missing+=("${cmd}")
        fi
    done

    if ${ok}; then
        json_response "ok" "All dependencies installed" 100 \
            '{"clang":"yes","cmake":"yes","ninja":"yes","llvm-ar":"yes"}'
    else
        json_response "error" "Missing: ${missing[*]}" 0 \
            "{\"missing\":\"${missing[*]}\"}"
    fi
}

# --- Main dispatcher ---------------------------------------------------------
main() {
    local command="${1:-help}"
    shift || true

    case "${command}" in
        create)       cmd_create_project "$@" ;;
        build)        cmd_build_project "$@" ;;
        clean)        cmd_clean_project "$@" ;;
        info)         cmd_project_info "$@" ;;
        templates)    cmd_list_templates ;;
        check-env)    cmd_check_env ;;
        version)
            json_response "ok" "NDK Lite v${NDK_LITE_VERSION}" 100
            ;;
        help|*)
            echo "NDK Lite Laragon Bridge v${NDK_LITE_VERSION}"
            echo ""
            echo "Commands:"
            echo "  create <type> <name>    Create new project"
            echo "  build <path> [type]     Build project"
            echo "  clean <path>            Clean project"
            echo "  info <path>             Get project info"
            echo "  templates               List available templates"
            echo "  check-env               Check environment"
            echo "  version                 Show version"
            ;;
    esac
}

main "$@"
