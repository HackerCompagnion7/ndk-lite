#!/data/data/com.termux/files/usr/bin/bash
# ============================================================================
# NDK Lite — Termux Package Builder
# Copyright (c) 2024-2026 Project Tomorrow Inc.
# Licensed under the Apache License, Version 2.0
# ============================================================================
#
# Builds .deb packages installable via Termux pkg install
#
# Usage:
#   build-packages.sh [package-name]
#   build-packages.sh all
#   build-packages.sh core
# ============================================================================

set -euo pipefail

NDK_LITE_VERSION="1.0.0"
TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NDK_LITE_HOME="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUTPUT_DIR="${NDK_LITE_HOME}/dist"

mkdir -p "${OUTPUT_DIR}"

# --- Package definitions -----------------------------------------------------
declare -A PACKAGES

PACKAGES[core]="NDK Lite Core — Toolchain, sysroot, and build scripts
Depends on clang, cmake, ninja
Provides the essential NDK Lite toolchain for Android ARM64 native development on Termux."

PACKAGES[opengl]="NDK Lite OpenGL — GLES2/EGL headers and stubs
Depends on ndk-lite-core
Provides OpenGL ES 2.0 and EGL headers for Android graphics development."

PACKAGES[jni]="NDK Lite JNI — Java Native Interface headers
Depends on ndk-lite-core
Provides JNI headers and bridge templates for Java-to-native communication."

PACKAGES[egl]="NDK Lite EGL — Native Platform Interface
Depends on ndk-lite-core, ndk-lite-opengl
Provides EGL headers and platform interface for Android window/surface management."

PACKAGES[vulkan]="NDK Lite Vulkan — Vulkan API headers
Depends on ndk-lite-core
Provides Vulkan API headers for next-generation Android graphics (v2 target)."

# --- Helper: create deb package ----------------------------------------------
build_deb_package() {
    local pkg_name="$1"
    local pkg_desc="$2"
    local pkg_dir="${OUTPUT_DIR}/ndk-lite-${pkg_name}_${NDK_LITE_VERSION}"

    echo "[NDK Lite] Building package: ndk-lite-${pkg_name}"

    # Create package structure
    mkdir -p "${pkg_dir}/DEBIAN"
    mkdir -p "${pkg_dir}/${TERMUX_PREFIX}/lib/ndk-lite"
    mkdir -p "${pkg_dir}/${TERMUX_PREFIX}/bin"
    mkdir -p "${pkg_dir}/${TERMUX_PREFIX}/share/doc/ndk-lite-${pkg_name}"

    # --- Control file ---
    local depends="clang, cmake, ninja"
    case "${pkg_name}" in
        opengl) depends="ndk-lite-core" ;;
        jni)    depends="ndk-lite-core" ;;
        egl)    depends="ndk-lite-core, ndk-lite-opengl" ;;
        vulkan) depends="ndk-lite-core" ;;
    esac

    cat > "${pkg_dir}/DEBIAN/control" << CONTROL
Package: ndk-lite-${pkg_name}
Version: ${NDK_LITE_VERSION}
Architecture: aarch64
Maintainer: Project Tomorrow Inc. <dev@projecttomorrow.inc>
Depends: ${depends}
Section: development
Priority: optional
Description: ${pkg_desc}
CONTROL

    # --- Install files based on package type ---
    case "${pkg_name}" in
        core)
            # Scripts
            cp -r "${NDK_LITE_HOME}/scripts/"*.sh "${pkg_dir}/${TERMUX_PREFIX}/lib/ndk-lite/" 2>/dev/null || true

            # Toolchain wrappers
            cp -r "${NDK_LITE_HOME}/src/toolchain/"*.sh "${pkg_dir}/${TERMUX_PREFIX}/lib/ndk-lite/" 2>/dev/null || true

            # CMake toolchain file
            mkdir -p "${pkg_dir}/${TERMUX_PREFIX}/lib/ndk-lite/cmake"
            cp "${NDK_LITE_HOME}/cmake/android-arm64-v8a.cmake" \
               "${pkg_dir}/${TERMUX_PREFIX}/lib/ndk-lite/cmake/"

            # Sysroot generator
            mkdir -p "${pkg_dir}/${TERMUX_PREFIX}/lib/ndk-lite/sysroot-gen"
            cp "${NDK_LITE_HOME}/src/sysroot/generate_sysroot.sh" \
               "${pkg_dir}/${TERMUX_LITE_PREFIX}/lib/ndk-lite/sysroot-gen/" 2>/dev/null || true

            # Create symlinks for commands
            for script in ndk-lite-build ndk-lite-new ndk-lite-setup \
                          ndk-lite-cc ndk-lite-cxx ndk-lite-ld \
                          ndk-lite-ar ndk-lite-ranlib; do
                if [[ -f "${pkg_dir}/${TERMUX_PREFIX}/lib/ndk-lite/${script}.sh" ]]; then
                    ln -sf "${TERMUX_PREFIX}/lib/ndk-lite/${script}.sh" \
                           "${pkg_dir}/${TERMUX_PREFIX}/bin/${script}"
                fi
            done

            # Basic headers (android/log.h, jni.h, dlfcn.h)
            mkdir -p "${pkg_dir}/${TERMUX_PREFIX}/include/ndk-lite/android"
            mkdir -p "${pkg_dir}/${TERMUX_PREFIX}/include/ndk-lite"
            cp "${NDK_LITE_HOME}/sysroot/usr/include/android/log.h" \
               "${pkg_dir}/${TERMUX_PREFIX}/include/ndk-lite/android/" 2>/dev/null || true
            cp "${NDK_LITE_HOME}/sysroot/usr/include/android/api-level.h" \
               "${pkg_dir}/${TERMUX_PREFIX}/include/ndk-lite/android/" 2>/dev/null || true
            cp "${NDK_LITE_HOME}/sysroot/usr/include/jni.h" \
               "${pkg_dir}/${TERMUX_PREFIX}/include/ndk-lite/" 2>/dev/null || true
            cp "${NDK_LITE_HOME}/sysroot/usr/include/dlfcn.h" \
               "${pkg_dir}/${TERMUX_PREFIX}/include/ndk-lite/" 2>/dev/null || true
            ;;

        opengl)
            mkdir -p "${pkg_dir}/${TERMUX_PREFIX}/include/ndk-lite/GLES2"
            mkdir -p "${pkg_dir}/${TERMUX_PREFIX}/include/ndk-lite/GLES3"
            mkdir -p "${pkg_dir}/${TERMUX_PREFIX}/include/ndk-lite/KHR"
            cp -r "${NDK_LITE_HOME}/sysroot/usr/include/GLES2/"* \
               "${pkg_dir}/${TERMUX_PREFIX}/include/ndk-lite/GLES2/" 2>/dev/null || true
            cp -r "${NDK_LITE_HOME}/sysroot/usr/include/KHR/"* \
               "${pkg_dir}/${TERMUX_PREFIX}/include/ndk-lite/KHR/" 2>/dev/null || true
            ;;

        jni)
            mkdir -p "${pkg_dir}/${TERMUX_PREFIX}/include/ndk-lite"
            cp "${NDK_LITE_HOME}/sysroot/usr/include/jni.h" \
               "${pkg_dir}/${TERMUX_PREFIX}/include/ndk-lite/" 2>/dev/null || true
            ;;

        egl)
            mkdir -p "${pkg_dir}/${TERMUX_PREFIX}/include/ndk-lite/EGL"
            cp -r "${NDK_LITE_HOME}/sysroot/usr/include/EGL/"* \
               "${pkg_dir}/${TERMUX_PREFIX}/include/ndk-lite/EGL/" 2>/dev/null || true
            ;;

        vulkan)
            mkdir -p "${pkg_dir}/${TERMUX_PREFIX}/include/ndk-lite/vulkan"
            echo "// Vulkan headers — Coming in NDK Lite v2" > \
                "${pkg_dir}/${TERMUX_PREFIX}/include/ndk-lite/vulkan/vulkan.h"
            ;;
    esac

    # --- Post-install script ---
    cat > "${pkg_dir}/DEBIAN/postinst" << POSTINST
#!/data/data/com.termux/files/usr/bin/bash
echo "[NDK Lite] ndk-lite-${pkg_name} installed successfully"
echo "[NDK Lite] Run 'ndk-lite-setup' to complete configuration"
POSTINST
    chmod +x "${pkg_dir}/DEBIAN/postinst"

    # --- License ---
    cp "${NDK_LITE_HOME}/LICENSE" \
       "${pkg_dir}/${TERMUX_PREFIX}/share/doc/ndk-lite-${pkg_name}/" 2>/dev/null || true

    # --- Build deb ---
    dpkg-deb --build "${pkg_dir}" 2>/dev/null || {
        echo "[NDK Lite] WARNING: dpkg-deb not available. Package directory created at:"
        echo "  ${pkg_dir}"
        return 0
    }

    local deb_file="${OUTPUT_DIR}/ndk-lite-${pkg_name}_${NDK_LITE_VERSION}_aarch64.deb"
    echo "[NDK Lite] Package built: ${deb_file}"
}

# --- Build requested packages ------------------------------------------------
if [[ $# -eq 0 ]] || [[ "$1" == "all" ]]; then
    for pkg in "${!PACKAGES[@]}"; do
        build_deb_package "${pkg}" "${PACKAGES[${pkg}]}"
    done
else
    pkg="$1"
    if [[ -n "${PACKAGES[${pkg}]+x}" ]]; then
        build_deb_package "${pkg}" "${PACKAGES[${pkg}]}"
    else
        echo "Unknown package: ${pkg}"
        echo "Available: ${!PACKAGES[*]}"
        exit 1
    fi
fi

echo ""
echo "[NDK Lite] All packages built in: ${OUTPUT_DIR}/"
echo "[NDK Lite] Install with: dpkg -i <package.deb>"
