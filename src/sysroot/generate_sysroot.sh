#!/data/data/com.termux/files/usr/bin/bash
# ============================================================================
# NDK Lite — Sysroot Generator for Android ARM64
# Copyright (c) 2024-2026 Project Tomorrow Inc.
# Licensed under the Apache License, Version 2.0
# ============================================================================
#
# This script generates the Android sysroot required for cross-compilation.
# It extracts headers and stub libraries from the Android NDK or creates
# minimal stubs when the NDK is not available.
#
# Strategy:
#   1. If Android NDK is available (downloaded), extract headers/stubs
#   2. If NDK is not available, generate minimal headers from known API
#   3. Use Termux's own bionic headers as fallback
#
# Usage:
#   ndk-lite-setup-sysroot [--api=26] [--ndk-path=/path/to/ndk]
# ============================================================================

set -euo pipefail

NDK_LITE_VERSION="1.0.0"

# --- Default configuration ---------------------------------------------------
API_LEVEL=26
NDK_PATH=""
TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

# --- Parse arguments ---------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --api=*)
            API_LEVEL="${1#*=}"
            shift
            ;;
        --ndk-path=*)
            NDK_PATH="${1#*=}"
            shift
            ;;
        --termux-prefix=*)
            TERMUX_PREFIX="${1#*=}"
            shift
            ;;
        --help)
            echo "Usage: ndk-lite-setup-sysroot [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --api=N           Android API level (default: 26)"
            echo "  --ndk-path=PATH   Path to Android NDK (optional)"
            echo "  --termux-prefix=  Termux prefix path"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# --- Resolve paths -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NDK_LITE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SYSROOT="${NDK_LITE_DIR}/sysroot"

echo "[NDK Lite] Generating sysroot at: ${SYSROOT}"
echo "[NDK Lite] Target API level: ${API_LEVEL}"

# --- Create directory structure ----------------------------------------------
mkdir -p "${SYSROOT}/usr/include"
mkdir -p "${SYSROOT}/usr/include/aarch64-linux-android"
mkdir -p "${SYSROOT}/usr/lib/aarch64-linux-android/${API_LEVEL}"
mkdir -p "${SYSROOT}/usr/lib/aarch64-linux-android"

# --- Strategy 1: Extract from NDK if available ------------------------------
if [[ -n "${NDK_PATH}" && -d "${NDK_PATH}" ]]; then
    echo "[NDK Lite] Extracting sysroot from NDK: ${NDK_PATH}"

    NDK_SYSROOT="${NDK_PATH}/toolchains/llvm/prebuilt/linux-x86_64/sysroot"

    if [[ -d "${NDK_SYSROOT}" ]]; then
        # Copy headers
        if [[ -d "${NDK_SYSROOT}/usr/include" ]]; then
            cp -r "${NDK_SYSROOT}/usr/include/"* "${SYSROOT}/usr/include/" 2>/dev/null || true
        fi

        # Copy arch-specific headers
        if [[ -d "${NDK_SYSROOT}/usr/include/aarch64-linux-android" ]]; then
            cp -r "${NDK_SYSROOT}/usr/include/aarch64-linux-android/"* \
                "${SYSROOT}/usr/include/aarch64-linux-android/" 2>/dev/null || true
        fi

        # Copy stub libraries
        if [[ -d "${NDK_SYSROOT}/usr/lib/aarch64-linux-android" ]]; then
            cp -r "${NDK_SYSROOT}/usr/lib/aarch64-linux-android/"*.o \
                "${SYSROOT}/usr/lib/aarch64-linux-android/" 2>/dev/null || true
            cp -r "${NDK_SYSROOT}/usr/lib/aarch64-linux-android/"*.a \
                "${SYSROOT}/usr/lib/aarch64-linux-android/" 2>/dev/null || true
        fi

        if [[ -d "${NDK_SYSROOT}/usr/lib/aarch64-linux-android/${API_LEVEL}" ]]; then
            cp -r "${NDK_SYSROOT}/usr/lib/aarch64-linux-android/${API_LEVEL}/"* \
                "${SYSROOT}/usr/lib/aarch64-linux-android/${API_LEVEL}/" 2>/dev/null || true
        fi

        echo "[NDK Lite] Sysroot extracted from NDK successfully."
        exit 0
    else
        echo "[NDK Lite] WARNING: NDK sysroot not found at ${NDK_SYSROOT}" >&2
        echo "[NDK Lite] Falling back to minimal stub generation..." >&2
    fi
fi

# --- Strategy 2: Generate minimal headers and stubs -------------------------
echo "[NDK Lite] Generating minimal Android sysroot stubs..."

# ---- android/log.h ---------------------------------------------------------
cat > "${SYSROOT}/usr/include/android/log.h" << 'HEADER'
/*
 * Android logging header — NDK Lite minimal stub
 * Copyright (c) 2024-2026 Project Tomorrow Inc.
 * Based on Android Open Source Project (Apache 2.0)
 */
#ifndef _ANDROID_LOG_H
#define _ANDROID_LOG_H

#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum android_LogPriority {
    ANDROID_LOG_UNKNOWN = 0,
    ANDROID_LOG_DEFAULT,
    ANDROID_LOG_VERBOSE,
    ANDROID_LOG_DEBUG,
    ANDROID_LOG_INFO,
    ANDROID_LOG_WARN,
    ANDROID_LOG_ERROR,
    ANDROID_LOG_FATAL,
    ANDROID_LOG_SILENT,
} android_LogPriority;

int __android_log_write(int prio, const char *tag, const char *text);
int __android_log_print(int prio, const char *tag, const char *fmt, ...)
    __attribute__((format(printf, 3, 4)));
int __android_log_vprint(int prio, const char *tag, const char *fmt, va_list ap);
int __android_log_assert(const char *cond, const char *tag, const char *fmt, ...)
    __attribute__((noreturn, format(printf, 3, 4)));

#define LOG_VERBOSE(tag, ...) __android_log_print(ANDROID_LOG_VERBOSE, tag, __VA_ARGS__)
#define LOG_DEBUG(tag, ...)   __android_log_print(ANDROID_LOG_DEBUG, tag, __VA_ARGS__)
#define LOG_INFO(tag, ...)    __android_log_print(ANDROID_LOG_INFO, tag, __VA_ARGS__)
#define LOG_WARN(tag, ...)    __android_log_print(ANDROID_LOG_WARN, tag, __VA_ARGS__)
#define LOG_ERROR(tag, ...)   __android_log_print(ANDROID_LOG_ERROR, tag, __VA_ARGS__)
#define LOG_FATAL(tag, ...)   __android_log_print(ANDROID_LOG_FATAL, tag, __VA_ARGS__)

#ifdef __cplusplus
}
#endif

#endif /* _ANDROID_LOG_H */
HEADER

# ---- android/api-level.h ---------------------------------------------------
cat > "${SYSROOT}/usr/include/android/api-level.h" << 'HEADER'
/*
 * Android API level header — NDK Lite minimal stub
 * Copyright (c) 2024-2026 Project Tomorrow Inc.
 */
#ifndef _ANDROID_API_LEVEL_H
#define _ANDROID_API_LEVEL_H

#define __ANDROID_API__ 26

/* API level constants */
#define __ANDROID_API_G__ 26
#define __ANDROID_API_O__ 26
#define __ANDROID_API_O_MR1__ 27
#define __ANDROID_API_P__ 28
#define __ANDROID_API_Q__ 29
#define __ANDROID_API_R__ 30
#define __ANDROID_API_S__ 31
#define __ANDROID_API_S_V2__ 32
#define __ANDROID_API_TIRAMISU__ 33
#define __ANDROID_API_U__ 34
#define __ANDROID_API_V__ 35

#endif /* _ANDROID_API_LEVEL_H */
HEADER

# ---- android/sharedmem.h ---------------------------------------------------
cat > "${SYSROOT}/usr/include/android/sharedmem.h" << 'HEADER'
/*
 * Android shared memory — NDK Lite minimal stub
 */
#ifndef _ANDROID_SHAREDMEM_H
#define _ANDROID_SHAREDMEM_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

int ASharedMemory_create(const char *name, size_t size);
size_t ASharedMemory_getSize(int fd);

#ifdef __cplusplus
}
#endif

#endif /* _ANDROID_SHAREDMEM_H */
HEADER

# ---- android/hardware_buffer.h ---------------------------------------------
cat > "${SYSROOT}/usr/include/android/hardware_buffer.h" << 'HEADER'
/*
 * Android hardware buffer — NDK Lite minimal stub
 */
#ifndef _ANDROID_HARDWARE_BUFFER_H
#define _ANDROID_HARDWARE_BUFFER_H

#include <sys/cdefs.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct AHardwareBuffer AHardwareBuffer;

typedef enum AHardwareBuffer_Format {
    AHARDWAREBUFFER_FORMAT_R8G8B8A8_UNORM = 1,
    AHARDWAREBUFFER_FORMAT_R8G8B8X8_UNORM = 2,
    AHARDWAREBUFFER_FORMAT_R8G8B8_UNORM   = 3,
    AHARDWAREBUFFER_FORMAT_R5G6B5_UNORM   = 4,
} AHardwareBuffer_Format;

AHardwareBuffer* AHardwareBuffer_acquire(AHardwareBuffer *buffer);
void AHardwareBuffer_release(AHardwareBuffer *buffer);

#ifdef __cplusplus
}
#endif

#endif /* _ANDROID_HARDWARE_BUFFER_H */
HEADER

# ---- jni.h -----------------------------------------------------------------
cat > "${SYSROOT}/usr/include/jni.h" << 'HEADER'
/*
 * JNI header — NDK Lite minimal stub
 * Copyright (c) 2024-2026 Project Tomorrow Inc.
 * Based on Android Open Source Project (Apache 2.0)
 */
#ifndef _JNI_H
#define _JNI_H

#include <stdarg.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Primitive types */
typedef uint8_t  jboolean;
typedef int8_t   jbyte;
typedef uint16_t jchar;
typedef int16_t  jshort;
typedef int32_t  jint;
typedef int64_t  jlong;
typedef float    jfloat;
typedef double   jdouble;
typedef jint     jsize;

/* Reference types */
typedef void*    jobject;
typedef jobject  jclass;
typedef jobject  jstring;
typedef jobject  jarray;
typedef jarray   jobjectArray;
typedef jarray   jbooleanArray;
typedef jarray   jbyteArray;
typedef jarray   jcharArray;
typedef jarray   jshortArray;
typedef jarray   jintArray;
typedef jarray   jlongArray;
typedef jarray   jfloatArray;
typedef jarray   jdoubleArray;
typedef jobject  jthrowable;
typedef jobject  jweak;

/* JNI return codes */
#define JNI_OK         0
#define JNI_ERR        (-1)
#define JNI_EDETACHED  (-2)
#define JNI_EVERSION   (-3)
#define JNI_ENOMEM     (-4)
#define JNI_EEXIST     (-5)
#define JNI_EINVAL     (-6)

/* JNI boolean values */
#define JNI_FALSE 0
#define JNI_TRUE  1

/* JavaVM */
typedef struct JavaVM JavaVM;

/* JNIEnv */
struct JNINativeInterface;
typedef const struct JNINativeInterface* JNIEnv;

/* JavaVMInitArgs */
typedef struct JavaVMInitArgs {
    jint version;
    jint nOptions;
    void* options;
    jboolean ignoreUnrecognized;
} JavaVMInitArgs;

/* JNI version constants */
#define JNI_VERSION_1_1  0x00010001
#define JNI_VERSION_1_2  0x00010002
#define JNI_VERSION_1_4  0x00010004
#define JNI_VERSION_1_6  0x00010006

/* Export macro */
#ifndef JNIEXPORT
#define JNIEXPORT __attribute__((visibility("default")))
#endif

#ifndef JNI_CALL
#define JNI_CALL
#endif

#define JNICALL

#ifdef __cplusplus
}
#endif

#endif /* _JNI_H */
HEADER

# ---- dlfcn.h (Android-specific) -------------------------------------------
cat > "${SYSROOT}/usr/include/dlfcn.h" << 'HEADER'
/*
 * Dynamic linking — NDK Lite minimal stub
 */
#ifndef _DLFCN_H
#define _DLFCN_H

#include <sys/cdefs.h>

#ifdef __cplusplus
extern "C" {
#endif

#define RTLD_LAZY     0x00001
#define RTLD_NOW      0x00002
#define RTLD_LOCAL    0x00000
#define RTLD_GLOBAL   0x00100
#define RTLD_NOLOAD   0x00004
#define RTLD_DEFAULT  ((void*)0)
#define RTLD_NEXT     ((void*)-1)

void*  dlopen(const char *filename, int flag);
int    dlclose(void *handle);
void*  dlsym(void *handle, const char *symbol);
char*  dlerror(void);

#ifdef __cplusplus
}
#endif

#endif /* _DLFCN_H */
HEADER

# ---- GLES2/gl2.h (OpenGL ES 2.0 stub) ------------------------------------
mkdir -p "${SYSROOT}/usr/include/GLES2"
cat > "${SYSROOT}/usr/include/GLES2/gl2.h" << 'HEADER'
/*
 * OpenGL ES 2.0 — NDK Lite minimal stub
 */
#ifndef _GLES2_GL2_H
#define _GLES2_GL2_H

#include <GLES2/gl2platform.h>
#include <KHR/khrplatform.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Basic types */
typedef void GLvoid;
typedef unsigned int GLenum;
typedef khronos_float_t GLfloat;
typedef int GLint;
typedef int GLsizei;
typedef unsigned int GLbitfield;
typedef double GLdouble;
typedef unsigned char GLboolean;
typedef khronos_uint8_t GLubyte;
typedef khronos_int8_t GLbyte;
typedef short GLshort;
typedef unsigned short GLushort;
typedef khronos_ssize_t GLsizeiptr;
typedef khronos_intptr_t GLintptr;
typedef char GLchar;

/* Boolean values */
#define GL_FALSE 0
#define GL_TRUE  1

/* Errors */
#define GL_NO_ERROR          0
#define GL_INVALID_ENUM      0x0500
#define GL_INVALID_VALUE     0x0501
#define GL_INVALID_OPERATION 0x0502
#define GL_OUT_OF_MEMORY     0x0505

/* Clearing */
#define GL_DEPTH_BUFFER_BIT   0x00000100
#define GL_STENCIL_BUFFER_BIT 0x00000400
#define GL_COLOR_BUFFER_BIT   0x00004000

/* Drawing */
#define GL_POINTS         0x0000
#define GL_LINES          0x0001
#define GL_LINE_LOOP      0x0002
#define GL_LINE_STRIP     0x0003
#define GL_TRIANGLES      0x0004
#define GL_TRIANGLE_STRIP 0x0005
#define GL_TRIANGLE_FAN   0x0006

/* Core functions */
void glClearColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
void glClear(GLbitfield mask);
void glViewport(GLint x, GLint y, GLsizei width, GLsizei height);
GLuint glCreateShader(GLenum type);
void glShaderSource(GLuint shader, GLsizei count, const GLchar* const* string, const GLint* length);
void glCompileShader(GLuint shader);
GLuint glCreateProgram(void);
void glAttachShader(GLuint program, GLuint shader);
void glLinkProgram(GLuint program);
void glUseProgram(GLuint program);
void glDrawArrays(GLenum mode, GLint first, GLsizei count);
void glDeleteShader(GLuint shader);
void glDeleteProgram(GLuint program);
GLenum glGetError(void);

/* Shaders */
#define GL_VERTEX_SHADER   0x8B31
#define GL_FRAGMENT_SHADER 0x8B30
#define GL_COMPILE_STATUS  0x8B81
#define GL_LINK_STATUS     0x8B82

void glGetShaderiv(GLuint shader, GLenum pname, GLint* params);
void glGetShaderInfoLog(GLuint shader, GLsizei bufSize, GLsizei* length, GLchar* infoLog);
void glGetProgramiv(GLuint program, GLenum pname, GLint* params);
void glGetProgramInfoLog(GLuint program, GLsizei bufSize, GLsizei* length, GLchar* infoLog);

typedef unsigned int GLuint;

#ifdef __cplusplus
}
#endif

#endif /* _GLES2_GL2_H */
HEADER

# ---- GLES2/gl2platform.h --------------------------------------------------
cat > "${SYSROOT}/usr/include/GLES2/gl2platform.h" << 'HEADER'
#ifndef _GLES2_GL2PLATFORM_H
#define _GLES2_GL2PLATFORM_H

#define GL_APICALL __attribute__((visibility("default")))
#define GL_APIENTRY

#endif
HEADER

# ---- KHR/khrplatform.h ----------------------------------------------------
mkdir -p "${SYSROOT}/usr/include/KHR"
cat > "${SYSROOT}/usr/include/KHR/khrplatform.h" << 'HEADER'
#ifndef _KHR_KHRPLATFORM_H
#define _KHR_KHRPLATFORM_H

typedef signed   char          khronos_int8_t;
typedef unsigned char          khronos_uint8_t;
typedef signed   short int     khronos_int16_t;
typedef unsigned short int     khronos_uint16_t;
typedef signed   int           khronos_int32_t;
typedef unsigned int           khronos_uint32_t;
typedef signed   long long int khronos_int64_t;
typedef unsigned long long int khronos_uint64_t;
typedef float                  khronos_float_t;
typedef signed   long int      khronos_intptr_t;
typedef signed   long int      khronos_ssize_t;
typedef unsigned long int      khronos_usize_t;
typedef unsigned long int      khronos_utime_nanoseconds_t;
typedef signed   long int      khronos_stime_nanoseconds_t;

#endif
HEADER

# ---- EGL/egl.h (minimal stub) --------------------------------------------
mkdir -p "${SYSROOT}/usr/include/EGL"
cat > "${SYSROOT}/usr/include/EGL/egl.h" << 'HEADER'
/*
 * EGL — NDK Lite minimal stub
 */
#ifndef _EGL_EGL_H
#define _EGL_EGL_H

#include <EGL/eglplatform.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void* EGLDisplay;
typedef void* EGLConfig;
typedef void* EGLSurface;
typedef void* EGLContext;
typedef void* EGLClientBuffer;
typedef unsigned int EGLBoolean;
typedef int32_t EGLint;

#define EGL_DEFAULT_DISPLAY ((EGLNativeDisplayType)0)
#define EGL_NO_DISPLAY      ((EGLDisplay)0)
#define EGL_NO_SURFACE      ((EGLSurface)0)
#define EGL_NO_CONTEXT      ((EGLContext)0)

#define EGL_SUCCESS          0x3000
#define EGL_NOT_INITIALIZED  0x3001
#define EGL_BAD_DISPLAY      0x3006
#define EGL_BAD_SURFACE      0x300D

#define EGL_RENDER_BUFFER    0x3086
#define EGL_BACK_BUFFER      0x3084

EGLDisplay eglGetDisplay(EGLNativeDisplayType display_id);
EGLBoolean eglInitialize(EGLDisplay dpy, EGLint *major, EGLint *minor);
EGLBoolean eglChooseConfig(EGLDisplay dpy, const EGLint *attrib_list,
                            EGLConfig *configs, EGLint config_size, EGLint *num_config);
EGLSurface eglCreateWindowSurface(EGLDisplay dpy, EGLConfig config,
                                   EGLNativeWindowType win, const EGLint *attrib_list);
EGLContext eglCreateContext(EGLDisplay dpy, EGLConfig config,
                             EGLContext share_context, const EGLint *attrib_list);
EGLBoolean eglMakeCurrent(EGLDisplay dpy, EGLSurface draw, EGLSurface read, EGLContext ctx);
EGLBoolean eglSwapBuffers(EGLDisplay dpy, EGLSurface surface);
EGLBoolean eglDestroySurface(EGLDisplay dpy, EGLSurface surface);
EGLBoolean eglDestroyContext(EGLDisplay dpy, EGLContext ctx);
EGLBoolean eglTerminate(EGLDisplay dpy);

#ifdef __cplusplus
}
#endif

#endif /* _EGL_EGL_H */
HEADER

# ---- EGL/eglplatform.h ---------------------------------------------------
cat > "${SYSROOT}/usr/include/EGL/eglplatform.h" << 'HEADER'
#ifndef _EGL_EGLPLATFORM_H
#define _EGL_EGLPLATFORM_H

#include <android/native_window.h>

typedef struct ANativeWindow* EGLNativeWindowType;
typedef void*                 EGLNativeDisplayType;
typedef int                   EGLNativePixmapType;

#endif
HEADER

# ---- android/native_window.h -----------------------------------------------
cat > "${SYSROOT}/usr/include/android/native_window.h" << 'HEADER'
#ifndef _ANDROID_NATIVE_WINDOW_H
#define _ANDROID_NATIVE_WINDOW_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct ANativeWindow ANativeWindow;

int32_t ANativeWindow_getWidth(ANativeWindow* window);
int32_t ANativeWindow_getHeight(ANativeWindow* window);

#ifdef __cplusplus
}
#endif

#endif
HEADER

# --- Strategy 3: Copy Termux system headers as supplement -------------------
echo "[NDK Lite] Checking for Termux system headers..."

TERMUX_INCLUDE="${TERMUX_PREFIX}/include"
if [[ -d "${TERMUX_INCLUDE}" ]]; then
    # Copy essential system headers that Android also provides
    for header_dir in sys bits asm linux; do
        if [[ -d "${TERMUX_INCLUDE}/${header_dir}" ]]; then
            cp -rn "${TERMUX_INCLUDE}/${header_dir}" "${SYSROOT}/usr/include/" 2>/dev/null || true
            echo "[NDK Lite]   Copied: ${header_dir}/"
        fi
    done

    # Copy individual essential headers
    for header in stdio.h stdlib.h string.h stdint.h stddef.h math.h time.h \
                  unistd.h fcntl.h errno.h pthread.h signal.h sched.h \
                  dirent.h stat.h ctype.h assert.h limits.h float.h \
                  setjmp.h locale.h wchar.h wctype.h inttypes.h; do
        if [[ -f "${TERMUX_INCLUDE}/${header}" ]]; then
            cp -n "${TERMUX_INCLUDE}/${header}" "${SYSROOT}/usr/include/" 2>/dev/null || true
        fi
    done
    echo "[NDK Lite]   System headers copied from Termux."
fi

# --- Generate linker stubs ---------------------------------------------------
echo "[NDK Lite] Generating linker stubs..."

# libc.so stub — just a linker script pointing to the system libc
cat > "${SYSROOT}/usr/lib/aarch64-linux-android/${API_LEVEL}/libc.so" << 'STUB'
/* GNU ld script — NDK Lite stub */
OUTPUT_FORMAT(elf64-littleaarch64)
GROUP ( /system/lib64/libc.so )
STUB

# libm.so stub
cat > "${SYSROOT}/usr/lib/aarch64-linux-android/${API_LEVEL}/libm.so" << 'STUB'
/* GNU ld script — NDK Lite stub */
OUTPUT_FORMAT(elf64-littleaarch64)
GROUP ( /system/lib64/libm.so )
STUB

# libdl.so stub
cat > "${SYSROOT}/usr/lib/aarch64-linux-android/${API_LEVEL}/libdl.so" << 'STUB'
/* GNU ld script — NDK Lite stub */
OUTPUT_FORMAT(elf64-littleaarch64)
GROUP ( /system/lib64/libdl.so )
STUB

# liblog.so stub
cat > "${SYSROOT}/usr/lib/aarch64-linux-android/${API_LEVEL}/liblog.so" << 'STUB'
/* GNU ld script — NDK Lite stub */
OUTPUT_FORMAT(elf64-littleaarch64)
GROUP ( /system/lib64/liblog.so )
STUB

# libandroid.so stub
cat > "${SYSROOT}/usr/lib/aarch64-linux-android/${API_LEVEL}/libandroid.so" << 'STUB'
/* GNU ld script — NDK Lite stub */
OUTPUT_FORMAT(elf64-littleaarch64)
GROUP ( /system/lib64/libandroid.so )
STUB

# libcrtbegin_dynamic.o stub (empty object)
if command -v llvm-ar &>/dev/null; then
    # Create minimal empty archive as stub
    printf '!<arch>\n' > "${SYSROOT}/usr/lib/aarch64-linux-android/crtbegin_dynamic.o"
    printf '!<arch>\n' > "${SYSROOT}/usr/lib/aarch64-linux-android/crtend_android.o"
fi

# --- Generate NDK Lite version metadata -------------------------------------
cat > "${SYSROOT}/usr/share/ndk-lite-metadata.h" << META
/*
 * NDK Lite Build Metadata
 * Auto-generated by ndk-lite-setup-sysroot
 */
#ifndef _NDK_LITE_METADATA_H
#define _NDK_LITE_METADATA_H

#define NDK_LITE_VERSION        "${NDK_LITE_VERSION}"
#define NDK_LITE_TARGET_ARCH    "arm64"
#define NDK_LITE_TARGET_ABI     "arm64-v8a"
#define NDK_LITE_TARGET_TRIPLE  "aarch64-linux-android"
#define NDK_LITE_API_LEVEL      ${API_LEVEL}

#endif
META

# --- Summary ----------------------------------------------------------------
HEADER_COUNT=$(find "${SYSROOT}/usr/include" -type f 2>/dev/null | wc -l)
LIB_COUNT=$(find "${SYSROOT}/usr/lib" -type f 2>/dev/null | wc -l)

echo ""
echo "============================================"
echo "  NDK Lite Sysroot Generated"
echo "============================================"
echo "  Location:     ${SYSROOT}"
echo "  API Level:    ${API_LEVEL}"
echo "  Headers:      ${HEADER_COUNT} files"
echo "  Lib stubs:    ${LIB_COUNT} files"
echo "============================================"
echo ""
echo "[NDK Lite] Next step: ndk-lite-build <project-dir>"
