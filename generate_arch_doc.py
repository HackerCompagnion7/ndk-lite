#!/usr/bin/env python3
"""
NDK Lite — Architecture Document PDF Generator
Copyright (c) 2024-2026 Project Tomorrow Inc.
"""

import os
import hashlib
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import inch, cm
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, KeepTogether, CondPageBreak
)
from reportlab.platypus.tableofcontents import TableOfContents
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase.pdfmetrics import registerFontFamily

# ═══════════════════════════════════════════════════════════════════════
# FONT REGISTRATION
# ═══════════════════════════════════════════════════════════════════════
pdfmetrics.registerFont(TTFont('LiberationSerif', '/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf'))
pdfmetrics.registerFont(TTFont('LiberationSerif-Bold', '/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf'))
pdfmetrics.registerFont(TTFont('Carlito', '/usr/share/fonts/truetype/english/Carlito-Regular.ttf'))
pdfmetrics.registerFont(TTFont('Carlito-Bold', '/usr/share/fonts/truetype/english/Carlito-Bold.ttf'))
pdfmetrics.registerFont(TTFont('DejaVuSans', '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'))
registerFontFamily('LiberationSerif', normal='LiberationSerif', bold='LiberationSerif-Bold')
registerFontFamily('Carlito', normal='Carlito', bold='Carlito-Bold')
registerFontFamily('DejaVuSans', normal='DejaVuSans', bold='DejaVuSans')

# ═══════════════════════════════════════════════════════════════════════
# PALETTE (auto-generated)
# ═══════════════════════════════════════════════════════════════════════
ACCENT       = colors.HexColor('#217591')
TEXT_PRIMARY  = colors.HexColor('#272623')
TEXT_MUTED    = colors.HexColor('#8d8a81')
BG_SURFACE   = colors.HexColor('#dedbd3')
BG_PAGE      = colors.HexColor('#f4f4f3')
TABLE_HEADER_COLOR = ACCENT
TABLE_HEADER_TEXT  = colors.white
TABLE_ROW_EVEN     = colors.white
TABLE_ROW_ODD      = BG_SURFACE

# ═══════════════════════════════════════════════════════════════════════
# STYLES
# ═══════════════════════════════════════════════════════════════════════
page_w, page_h = A4
left_margin = 1.0 * inch
right_margin = 1.0 * inch
available_width = page_w - left_margin - right_margin

styles = {
    'title': ParagraphStyle(
        name='DocTitle', fontName='LiberationSerif', fontSize=28,
        leading=34, textColor=ACCENT, alignment=TA_CENTER, spaceAfter=6
    ),
    'subtitle': ParagraphStyle(
        name='DocSubtitle', fontName='LiberationSerif', fontSize=14,
        leading=20, textColor=TEXT_MUTED, alignment=TA_CENTER, spaceAfter=24
    ),
    'h1': ParagraphStyle(
        name='H1', fontName='LiberationSerif', fontSize=20,
        leading=28, textColor=ACCENT, spaceBefore=24, spaceAfter=12
    ),
    'h2': ParagraphStyle(
        name='H2', fontName='LiberationSerif', fontSize=16,
        leading=22, textColor=ACCENT, spaceBefore=18, spaceAfter=8
    ),
    'h3': ParagraphStyle(
        name='H3', fontName='LiberationSerif', fontSize=13,
        leading=18, textColor=TEXT_PRIMARY, spaceBefore=12, spaceAfter=6
    ),
    'body': ParagraphStyle(
        name='Body', fontName='LiberationSerif', fontSize=10.5,
        leading=17, textColor=TEXT_PRIMARY, alignment=TA_JUSTIFY,
        spaceAfter=8, firstLineIndent=0
    ),
    'code': ParagraphStyle(
        name='Code', fontName='DejaVuSans', fontSize=8.5,
        leading=12, textColor=colors.HexColor('#1a1a1a'),
        backColor=colors.HexColor('#f0f0f0'),
        leftIndent=12, rightIndent=12, spaceAfter=8, spaceBefore=4
    ),
    'caption': ParagraphStyle(
        name='Caption', fontName='LiberationSerif', fontSize=9,
        leading=13, textColor=TEXT_MUTED, alignment=TA_CENTER,
        spaceBefore=3, spaceAfter=6
    ),
    'toc_h1': ParagraphStyle(
        name='TOCHeading1', fontSize=12, leftIndent=20,
        fontName='LiberationSerif', spaceBefore=6
    ),
    'toc_h2': ParagraphStyle(
        name='TOCHeading2', fontSize=10, leftIndent=40,
        fontName='LiberationSerif', spaceBefore=2
    ),
    'header_cell': ParagraphStyle(
        name='HeaderCell', fontName='LiberationSerif', fontSize=10,
        textColor=colors.white, alignment=TA_CENTER
    ),
    'cell': ParagraphStyle(
        name='Cell', fontName='LiberationSerif', fontSize=9.5,
        textColor=TEXT_PRIMARY, alignment=TA_CENTER
    ),
    'cell_left': ParagraphStyle(
        name='CellLeft', fontName='LiberationSerif', fontSize=9.5,
        textColor=TEXT_PRIMARY, alignment=TA_LEFT
    ),
}

# ═══════════════════════════════════════════════════════════════════════
# TOC DOC TEMPLATE
# ═══════════════════════════════════════════════════════════════════════
H1_ORPHAN_THRESHOLD = (page_h - left_margin - right_margin) * 0.15

class TocDocTemplate(SimpleDocTemplate):
    def afterFlowable(self, flowable):
        if hasattr(flowable, 'bookmark_name'):
            level = getattr(flowable, 'bookmark_level', 0)
            text = getattr(flowable, 'bookmark_text', '')
            key = getattr(flowable, 'bookmark_key', '')
            self.notify('TOCEntry', (level, text, self.page, key))

def add_heading(text, style_key, level=0):
    key = 'h_%s' % hashlib.md5(text.encode()).hexdigest()[:8]
    p = Paragraph('<a name="%s"/>%s' % (key, text), styles[style_key])
    p.bookmark_name = text
    p.bookmark_level = level
    p.bookmark_text = text
    p.bookmark_key = key
    return p

def make_table(headers, rows, col_ratios=None):
    """Create a styled table with header and data rows."""
    n_cols = len(headers)
    if col_ratios is None:
        col_ratios = [1.0 / n_cols] * n_cols
    col_widths = [r * available_width for r in col_ratios]

    data = []
    hdr = [Paragraph('<b>%s</b>' % h, styles['header_cell']) for h in headers]
    data.append(hdr)
    for row in rows:
        data.append([Paragraph(str(c), styles['cell_left']) for c in row])

    t = Table(data, colWidths=col_widths, hAlign='CENTER')
    style_cmds = [
        ('BACKGROUND', (0, 0), (-1, 0), TABLE_HEADER_COLOR),
        ('TEXTCOLOR', (0, 0), (-1, 0), TABLE_HEADER_TEXT),
        ('GRID', (0, 0), (-1, -1), 0.5, TEXT_MUTED),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('RIGHTPADDING', (0, 0), (-1, -1), 8),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
    ]
    for i in range(1, len(data)):
        bg = TABLE_ROW_EVEN if i % 2 == 1 else TABLE_ROW_ODD
        style_cmds.append(('BACKGROUND', (0, i), (-1, i), bg))
    t.setStyle(TableStyle(style_cmds))
    return t

# ═══════════════════════════════════════════════════════════════════════
# BUILD DOCUMENT
# ═══════════════════════════════════════════════════════════════════════
output_path = '/home/z/my-project/download/ndk-lite/NDK_Lite_Architecture_Document.pdf'

doc = TocDocTemplate(
    output_path,
    pagesize=A4,
    leftMargin=left_margin,
    rightMargin=right_margin,
    topMargin=0.8*inch,
    bottomMargin=0.8*inch,
    title='NDK Lite Architecture Document',
    author='Project Tomorrow Inc.',
    creator='Z.ai',
)

story = []

# ─── Title Page ──────────────────────────────────────────────────────────
story.append(Spacer(1, 120))
story.append(Paragraph('<b>NDK Lite</b>', styles['title']))
story.append(Spacer(1, 8))
story.append(Paragraph('Architecture Document', ParagraphStyle(
    'BigSub', fontName='LiberationSerif', fontSize=22,
    leading=28, textColor=ACCENT, alignment=TA_CENTER, spaceAfter=12
)))
story.append(Spacer(1, 24))
story.append(Paragraph('Android ARM64 Native Development Toolkit for Termux', styles['subtitle']))
story.append(Spacer(1, 36))
story.append(Paragraph('Version 1.0.0', ParagraphStyle(
    'Version', fontName='LiberationSerif', fontSize=12,
    leading=16, textColor=TEXT_MUTED, alignment=TA_CENTER
)))
story.append(Spacer(1, 8))
story.append(Paragraph('Project Tomorrow Inc.', ParagraphStyle(
    'Company', fontName='LiberationSerif', fontSize=12,
    leading=16, textColor=TEXT_MUTED, alignment=TA_CENTER
)))
story.append(Spacer(1, 8))
story.append(Paragraph('2024-2026', ParagraphStyle(
    'Year', fontName='LiberationSerif', fontSize=12,
    leading=16, textColor=TEXT_MUTED, alignment=TA_CENTER
)))
story.append(PageBreak())

# ─── Table of Contents ──────────────────────────────────────────────────
story.append(Paragraph('<b>Table of Contents</b>', styles['h1']))
toc = TableOfContents()
toc.levelStyles = [styles['toc_h1'], styles['toc_h2']]
story.append(toc)
story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# SECTION 1: EXECUTIVE SUMMARY
# ═══════════════════════════════════════════════════════════════════════
story.append(CondPageBreak(H1_ORPHAN_THRESHOLD))
story.append(add_heading('1. Executive Summary', 'h1', 0))

story.append(Paragraph(
    'NDK Lite is a lightweight, fully native alternative to the official Android NDK, '
    'engineered specifically for Android ARM64 devices running Termux. The project addresses '
    'a critical gap in the Android development ecosystem: the inability to compile native C/C++ '
    'code directly on an Android device without access to a desktop computer running Linux, '
    'Windows, or macOS. The official Android NDK distributes host tools exclusively as x86_64 '
    'ELF binaries, which cannot execute on ARM64 architectures without emulation layers that '
    'introduce significant performance overhead and complexity.',
    styles['body']
))

story.append(Paragraph(
    'NDK Lite solves this by leveraging Termux\'s native ARM64 LLVM/Clang toolchain and '
    'injecting Android-specific target flags, sysroot headers, and linker configurations. '
    'The result is a zero-emulation, zero-compromise development environment where the entire '
    'compilation pipeline runs natively on the device. Developers can create, build, test, and '
    'iterate on native libraries entirely from their phone or tablet, removing the dependency on '
    'desktop infrastructure and enabling a new class of mobile-native development workflows.',
    styles['body']
))

story.append(Paragraph(
    'The architecture is organized into five distinct layers: the Toolchain Layer providing '
    'compiler and linker wrappers, the Sysroot Layer delivering Android headers and library stubs, '
    'the Build Integration Layer automating CMake and Ninja configuration, the Package Layer '
    'enabling modular Termux package installation, and the Laragon Integration Layer providing '
    'a JSON-based bridge for visual development environments. Version 1.0 supports static and '
    'shared libraries in C and C++, JNI bridge compilation, and automated project scaffolding '
    'through the ndk-lite-new and ndk-lite-build commands.',
    styles['body']
))

# ═══════════════════════════════════════════════════════════════════════
# SECTION 2: PROBLEM STATEMENT
# ═══════════════════════════════════════════════════════════════════════
story.append(CondPageBreak(H1_ORPHAN_THRESHOLD))
story.append(add_heading('2. Problem Statement', 'h1', 0))

story.append(Paragraph(
    'The Android NDK is the standard toolchain for compiling native C and C++ code that '
    'integrates with the Android platform. However, the NDK distributes its host-side tools '
    '(compilers, linkers, archivers) as ELF binaries compiled for x86_64 architectures. This '
    'means that developers working directly on Android ARM64 devices through Termux are entirely '
    'locked out of the native development workflow. The fundamental incompatibility is architectural: '
    'an ARM64 processor cannot natively execute x86_64 instructions, and while binary translation '
    'layers like QEMU exist, they introduce 5-20x performance degradation and require complex '
    'configuration that defeats the purpose of an integrated development environment.',
    styles['body']
))

story.append(add_heading('2.1 The x86_64 Binary Wall', 'h2', 1))

story.append(Paragraph(
    'Consider the standard NDK directory structure. The toolchain lives under '
    'toolchains/llvm/prebuilt/linux-x86_64/, containing clang, clang++, lld, llvm-ar, '
    'and other essential tools. These are ELF x86_64 executables. When a developer attempts '
    'to run any of these on a Termux shell on their Android phone, the kernel rejects the '
    'execution with a "Exec format error" because the binary format does not match the host '
    'architecture. This is not a configuration issue; it is a fundamental ISA mismatch that '
    'cannot be resolved without either cross-compilation from an x86_64 host or a native '
    'ARM64 toolchain.',
    styles['body']
))

story.append(Paragraph(
    'The practical impact is significant. Developers who want to build native libraries on '
    'Android must maintain access to a desktop development machine, install Android Studio or '
    'the standalone NDK, configure their build environment, and then transfer artifacts back '
    'to the device for testing. This round-trip workflow is inefficient for rapid iteration, '
    'impossible in field scenarios where desktop access is unavailable, and creates a barrier '
    'to entry for developers whose primary or only computing device is a smartphone.',
    styles['body']
))

# ═══════════════════════════════════════════════════════════════════════
# SECTION 3: ARCHITECTURE OVERVIEW
# ═══════════════════════════════════════════════════════════════════════
story.append(CondPageBreak(H1_ORPHAN_THRESHOLD))
story.append(add_heading('3. Architecture Overview', 'h1', 0))

story.append(Paragraph(
    'NDK Lite is designed as a layered architecture where each layer has a single, well-defined '
    'responsibility and communicates with adjacent layers through standard interfaces. This '
    'separation ensures that individual layers can be updated, replaced, or extended without '
    'affecting the rest of the system. The five layers, from lowest to highest abstraction, are: '
    'Toolchain, Sysroot, Build Integration, Package, and Laragon Integration.',
    styles['body']
))

story.append(Spacer(1, 12))
t = make_table(
    ['Layer', 'Responsibility', 'Key Components'],
    [
        ['Toolchain', 'Compiler and linker wrappers', 'ndk-lite-cc, ndk-lite-cxx, ndk-lite-ld, ndk-lite-ar, ndk-lite-ranlib'],
        ['Sysroot', 'Android headers and library stubs', 'generate_sysroot.sh, android/log.h, jni.h, GLES2/gl2.h, EGL/egl.h, linker scripts'],
        ['Build Integration', 'CMake/Ninja automation', 'android-arm64-v8a.cmake, ndk-lite-build, ndk-lite-new'],
        ['Package', 'Termux package distribution', 'build-packages.sh, ndk-lite-core, ndk-lite-opengl, ndk-lite-jni, ndk-lite-egl'],
        ['Laragon Integration', 'Visual IDE bridge', 'ndk-lite-laragon-bridge.sh, JSON protocol'],
    ],
    [0.15, 0.35, 0.50]
)
story.append(t)
story.append(Paragraph('<b>Table 1.</b> NDK Lite Architecture Layers', styles['caption']))
story.append(Spacer(1, 12))

story.append(Paragraph(
    'The data flow through the system follows a clear path. The developer invokes ndk-lite-build '
    'on a project directory. The Build Integration Layer reads the project configuration, loads '
    'the CMake toolchain file (which references the Sysroot Layer), invokes Termux\'s native '
    'clang/clang++ through the Toolchain Layer wrappers, and produces native Android ARM64 '
    'artifacts. At no point does the pipeline depend on x86_64 binaries, emulation, or external '
    'desktop infrastructure.',
    styles['body']
))

# ═══════════════════════════════════════════════════════════════════════
# SECTION 4: TOOLCHAIN LAYER
# ═══════════════════════════════════════════════════════════════════════
story.append(CondPageBreak(H1_ORPHAN_THRESHOLD))
story.append(add_heading('4. Toolchain Layer', 'h1', 0))

story.append(Paragraph(
    'The Toolchain Layer is the foundation of NDK Lite. It provides wrapper scripts around '
    'Termux\'s native ARM64 LLVM/Clang binaries that automatically inject Android target flags, '
    'sysroot paths, and platform-specific compiler options. The design principle is that developers '
    'should be able to use these wrappers as drop-in replacements for the NDK\'s x86_64 compilers '
    'without changing their build scripts or learning new command-line interfaces.',
    styles['body']
))

story.append(add_heading('4.1 Compiler Wrappers', 'h2', 1))

story.append(Paragraph(
    'The ndk-lite-cc and ndk-lite-cxx scripts wrap Termux\'s clang and clang++ binaries '
    'respectively. Each wrapper performs three critical operations before delegating to the '
    'underlying compiler. First, it resolves the Termux prefix path by checking the TERMUX_PREFIX '
    'and PREFIX environment variables, falling back to the default /data/data/com.termux/files/usr. '
    'Second, it locates the NDK Lite sysroot relative to its own installation path. Third, it '
    'constructs and injects the target triple flag (--target=aarch64-linux-android<API>), the '
    'sysroot flag (--sysroot=<path>), and a set of Android-specific defines (-DANDROID, '
    '-D__ANDROID__, -DNDK_LITE) along with position-independent code and security hardening flags.',
    styles['body']
))

story.append(Paragraph(
    'The wrapper scripts support additional configuration through command-line flags. The '
    '--ndk-lite-api=N flag overrides the default API level (26) for targeting different Android '
    'versions. The --ndk-lite-stl=c++_static|c++_shared flag controls the C++ standard library '
    'linkage strategy. These flags are parsed and stripped from the argument list before the '
    'remaining arguments are passed through to the underlying compiler, ensuring full compatibility '
    'with existing build systems.',
    styles['body']
))

story.append(add_heading('4.2 Linker Wrapper', 'h2', 1))

story.append(Paragraph(
    'The ndk-lite-ld script wraps the clang++ driver as a linker frontend, explicitly requesting '
    'LLVM\'s LLD linker via the -fuse-ld=lld flag. This approach is preferred over invoking ld.lld '
    'directly because the clang driver automatically handles CRT object file selection, standard '
    'library linkage, and platform-specific linker script processing. The wrapper injects '
    'Android-specific linker flags including --build-id=sha1 for build identification, '
    '--gc-sections for dead code elimination, and -landroid -llog for Android platform library '
    'linkage. For shared library output, it also adds -Wl,-soname and -Wl,--no-undefined to '
    'ensure proper library naming and symbol resolution at link time.',
    styles['body']
))

story.append(add_heading('4.3 Archiver Wrapper', 'h2', 1))

story.append(Paragraph(
    'The ndk-lite-ar and ndk-lite-ranlib scripts provide thin wrappers around llvm-ar and '
    'llvm-ranlib from Termux\'s LLVM package. These tools create and index static library '
    'archives (.a files) compatible with the Android ARM64 target. Since llvm-ar produces '
    'architecture-independent archive formats, the wrapper primarily verifies tool availability '
    'and provides a consistent command-line interface that mirrors the NDK\'s tool naming convention.',
    styles['body']
))

# ═══════════════════════════════════════════════════════════════════════
# SECTION 5: SYSROOT LAYER
# ═══════════════════════════════════════════════════════════════════════
story.append(CondPageBreak(H1_ORPHAN_THRESHOLD))
story.append(add_heading('5. Android Sysroot Layer', 'h1', 0))

story.append(Paragraph(
    'The Sysroot Layer provides the Android-specific headers and library stubs that the compiler '
    'and linker need to produce Android-compatible native code. Unlike desktop Linux where the '
    'system headers and libraries are readily available, Android\'s bionic libc, JNI headers, and '
    'platform library stubs are not part of Termux\'s standard installation. NDK Lite fills this '
    'gap through a multi-strategy sysroot generator that can extract headers from an existing NDK '
    'installation or generate minimal but functional header stubs when the NDK is not available.',
    styles['body']
))

story.append(add_heading('5.1 Three-Strategy Generation', 'h2', 1))

story.append(Paragraph(
    'The generate_sysroot.sh script implements three fallback strategies for building the sysroot. '
    'Strategy 1 extracts headers and library stubs from an existing Android NDK installation if '
    'the user provides the --ndk-path flag. This produces the most complete sysroot with full API '
    'coverage. Strategy 2 generates minimal but functional header stubs for critical Android APIs '
    'including android/log.h for logging, jni.h for Java Native Interface, dlfcn.h for dynamic '
    'linking, GLES2/gl2.h for OpenGL ES 2.0, and EGL/egl.h for the native platform interface. '
    'Strategy 3 supplements the generated stubs by copying essential system headers (sys/, bits/, '
    'asm/, linux/) from Termux\'s own include directory, since Termux\'s bionic headers are '
    'compatible with the Android target.',
    styles['body']
))

story.append(add_heading('5.2 Library Stubs Strategy', 'h2', 1))

story.append(Paragraph(
    'For runtime library linkage, NDK Lite employs a linker script strategy rather than shipping '
    'actual binary stubs. Each library stub (libc.so, libm.so, libdl.so, liblog.so, libandroid.so) '
    'is a GNU ld script that redirects the linker to the corresponding library in the device\'s '
    '/system/lib64/ directory. This approach has several advantages. First, it avoids shipping '
    'binary files that would need to be updated for each Android API level. Second, it guarantees '
    'compatibility with the exact system libraries installed on the target device. Third, it keeps '
    'the NDK Lite package size minimal since linker scripts are plain text files measured in bytes '
    'rather than kilobytes or megabytes.',
    styles['body']
))

story.append(add_heading('5.3 Header Coverage', 'h2', 1))

story.append(Spacer(1, 6))
t = make_table(
    ['Header', 'Category', 'APIs Provided'],
    [
        ['android/log.h', 'Logging', '__android_log_print, __android_log_write, __android_log_assert'],
        ['android/api-level.h', 'Platform', '__ANDROID_API__, API level constants'],
        ['android/native_window.h', 'Window', 'ANativeWindow, width/height queries'],
        ['jni.h', 'JNI', 'jobject, jclass, jstring, JavaVM, JNIEnv, JNI_OnLoad'],
        ['dlfcn.h', 'Dynamic Linking', 'dlopen, dlsym, dlclose, dlerror'],
        ['GLES2/gl2.h', 'OpenGL ES 2.0', 'glCreateShader, glLinkProgram, glDrawArrays, etc.'],
        ['EGL/egl.h', 'EGL', 'eglGetDisplay, eglCreateContext, eglSwapBuffers, etc.'],
    ],
    [0.22, 0.18, 0.60]
)
story.append(t)
story.append(Paragraph('<b>Table 2.</b> NDK Lite Header Coverage (v1.0)', styles['caption']))

# ═══════════════════════════════════════════════════════════════════════
# SECTION 6: BUILD INTEGRATION LAYER
# ═══════════════════════════════════════════════════════════════════════
story.append(CondPageBreak(H1_ORPHAN_THRESHOLD))
story.append(add_heading('6. Build Integration Layer', 'h1', 0))

story.append(Paragraph(
    'The Build Integration Layer automates the configuration and execution of CMake and Ninja '
    'builds, abstracting away the complexity of cross-compilation toolchain setup. The two '
    'primary commands are ndk-lite-build for compiling existing projects and ndk-lite-new for '
    'creating new projects from templates. Together, they provide a complete build lifecycle '
    'that requires zero manual toolchain configuration from the developer.',
    styles['body']
))

story.append(add_heading('6.1 CMake Toolchain File', 'h2', 1))

story.append(Paragraph(
    'The android-arm64-v8a.cmake toolchain file is the central piece of the Build Integration '
    'Layer. It configures CMake for Android cross-compilation by setting CMAKE_SYSTEM_NAME to '
    'Android, locating the Termux LLVM/Clang binaries, configuring compiler flags with the '
    'correct target triple (--target=aarch64-linux-android<API>), and pointing the sysroot to '
    'the NDK Lite sysroot directory. The toolchain file also sets up the complete tool chain '
    'including the archiver (llvm-ar), ranlib (llvm-ranlib), strip (llvm-strip), and other LLVM '
    'tools. When loaded by CMake, it prints a detailed configuration summary showing the target, '
    'ABI, STL type, sysroot path, and compiler locations, giving the developer immediate feedback '
    'that the cross-compilation environment is correctly configured.',
    styles['body']
))

story.append(add_heading('6.2 ndk-lite-build Command', 'h2', 1))

story.append(Paragraph(
    'The ndk-lite-build command orchestrates the entire build process in three phases. Phase 1 '
    '(Configure) invokes CMake with the toolchain file and project-specific options such as '
    'ANDROID_ABI, ANDROID_PLATFORM, ANDROID_STL, and BUILD_SHARED_LIBS. Phase 2 (Build) executes '
    'Ninja or Make with the specified number of parallel jobs (defaulting to the device\'s CPU '
    'core count). Phase 3 (Collect) scans the build directory for .so and .a artifacts and copies '
    'them to the output directory. The command supports extensive customization through flags '
    'including --type=static|shared, --api=N, --stl=c++_static|c++_shared, --debug, --release, '
    '--clean, --verbose, --gen=make|ninja, and -jN for parallelism control.',
    styles['body']
))

story.append(add_heading('6.3 ndk-lite-new Command', 'h2', 1))

story.append(Paragraph(
    'The ndk-lite-new command creates fully structured project directories from templates. '
    'Four template types are supported in version 1.0. The "cpp" template generates a C++ '
    'library project with CMakeLists.txt, source files, public headers, and an ndk-lite.config '
    'file. The "c" template provides the equivalent for C projects. The "jni" template creates '
    'a JNI bridge project with JNI header stubs and a Java-to-native bridge implementation. '
    'The "opengl" template generates an OpenGL ES 2.0 renderer project with EGL context '
    'management and GLES2 shader compilation scaffolding. Each template includes a .gitignore, '
    'README.md, and ndk-lite.config file with sensible defaults.',
    styles['body']
))

# ═══════════════════════════════════════════════════════════════════════
# SECTION 7: PACKAGE LAYER
# ═══════════════════════════════════════════════════════════════════════
story.append(CondPageBreak(H1_ORPHAN_THRESHOLD))
story.append(add_heading('7. Package Layer', 'h1', 0))

story.append(Paragraph(
    'The Package Layer enables modular installation of NDK Lite components through Termux\'s '
    'native package management system. Rather than installing a monolithic toolchain, developers '
    'can install only the components they need, reducing storage requirements and keeping the '
    'development environment lean. The build-packages.sh script generates Debian-format packages '
    'compatible with Termux\'s dpkg infrastructure.',
    styles['body']
))

story.append(Spacer(1, 6))
t = make_table(
    ['Package', 'Dependencies', 'Contents'],
    [
        ['ndk-lite-core', 'clang, cmake, ninja', 'Build scripts, toolchain wrappers, CMake toolchain file, basic Android headers'],
        ['ndk-lite-opengl', 'ndk-lite-core', 'GLES2/GLES3 headers, KHR platform headers'],
        ['ndk-lite-jni', 'ndk-lite-core', 'JNI headers, bridge templates'],
        ['ndk-lite-egl', 'ndk-lite-core, ndk-lite-opengl', 'EGL headers, native window headers'],
        ['ndk-lite-vulkan', 'ndk-lite-core', 'Vulkan API headers (v2 roadmap)'],
    ],
    [0.18, 0.25, 0.57]
)
story.append(t)
story.append(Paragraph('<b>Table 3.</b> NDK Lite Package Definitions', styles['caption']))

story.append(Paragraph(
    'Each package includes a DEBIAN/control file with proper dependency declarations, a '
    'post-installation script that prints confirmation and setup reminders, and the actual '
    'files installed to the Termux prefix. The core package creates symlinks in Termux\'s bin '
    'directory for all ndk-lite-* commands, making them immediately available in the user\'s PATH. '
    'This modular approach means a developer who only needs basic C/C++ compilation can install '
    'ndk-lite-core at roughly 200KB, while a developer building graphics applications can add '
    'ndk-lite-opengl and ndk-lite-egl for an additional 50KB of headers.',
    styles['body']
))

# ═══════════════════════════════════════════════════════════════════════
# SECTION 8: LARAGON INTEGRATION
# ═══════════════════════════════════════════════════════════════════════
story.append(CondPageBreak(H1_ORPHAN_THRESHOLD))
story.append(add_heading('8. Laragon Integration Layer', 'h1', 0))

story.append(Paragraph(
    'The Laragon Integration Layer provides a JSON-based communication bridge between NDK Lite\'s '
    'CLI commands and the Laragon OS visual development environment. When a user interacts with '
    'Laragon\'s GUI (for example, clicking "Create C++ Project" or "Build"), Laragon invokes the '
    'ndk-lite-laragon-bridge.sh script with the appropriate command and parameters. The bridge '
    'executes the corresponding NDK Lite CLI command and returns structured JSON responses that '
    'Laragon translates into progress bars, status messages, and visual indicators.',
    styles['body']
))

story.append(Paragraph(
    'The JSON response format follows a consistent schema with four fields: status (ok or error), '
    'message (human-readable description), progress (integer 0-100 representing completion '
    'percentage), and data (optional JSON object with structured results). This protocol enables '
    'real-time progress reporting during long builds, structured error reporting with actionable '
    'information, and rich result data including file paths, project metadata, and environment '
    'status. The bridge supports six commands: create (project creation), build (compilation), '
    'clean (artifact removal), info (project metadata), templates (available project types), and '
    'check-env (dependency verification).',
    styles['body']
))

# ═══════════════════════════════════════════════════════════════════════
# SECTION 9: DIRECTORY STRUCTURE
# ═══════════════════════════════════════════════════════════════════════
story.append(CondPageBreak(H1_ORPHAN_THRESHOLD))
story.append(add_heading('9. Project Directory Structure', 'h1', 0))

story.append(Paragraph(
    'The NDK Lite project is organized into clearly separated directories by functional layer. '
    'The top-level directory contains documentation files (README.md, LICENSE, CONTRIBUTING.md), '
    'configuration directories (cmake/, configs/), and source directories (src/, scripts/, tests/). '
    'The generated sysroot lives at the project root and is created by the setup script. This '
    'structure allows the project to be cloned, configured, and used without modifying any files '
    'outside the designated output directories.',
    styles['body']
))

structure_text = """ndk-lite/
+-- cmake/android-arm64-v8a.cmake
+-- scripts/
|   +-- ndk-lite-build.sh
|   +-- ndk-lite-new.sh
|   +-- ndk-lite-setup.sh
+-- src/
|   +-- toolchain/
|   |   +-- ndk-lite-cc.sh
|   |   +-- ndk-lite-cxx.sh
|   |   +-- ndk-lite-ld.sh
|   |   +-- ndk-lite-ar.sh
|   |   +-- ndk-lite-ranlib.sh
|   +-- sysroot/generate_sysroot.sh
|   +-- package/build-packages.sh
|   +-- laragon/ndk-lite-laragon-bridge.sh
+-- sysroot/  (generated)
|   +-- usr/include/  (Android headers)
|   +-- usr/lib/  (library stubs)
+-- tests/assimp_lite/  (validation project)
+-- LICENSE  (Apache 2.0)
+-- README.md
+-- CONTRIBUTING.md"""

story.append(Paragraph(structure_text.replace('<', '&lt;').replace('>', '&gt;').replace('\n', '<br/>').replace(' ', '&nbsp;'), styles['code']))

# ═══════════════════════════════════════════════════════════════════════
# SECTION 10: VALIDATION CASE
# ═══════════════════════════════════════════════════════════════════════
story.append(CondPageBreak(H1_ORPHAN_THRESHOLD))
story.append(add_heading('10. Validation: assimp_lite', 'h1', 0))

story.append(Paragraph(
    'The assimp_lite project serves as the mandatory validation case for NDK Lite. It is a '
    'minimal but structurally representative subset of the Assimp 3D model loading library, '
    'designed to exercise all critical features of the toolchain. The project includes C++ '
    'classes with inheritance and templates (format_loader base class with obj_loader and '
    'stl_loader subclasses), math types with operator overloading (vec3, mat4, quaternion), '
    'Android logging integration through __android_log_print, scene graph management with '
    'smart pointers (std::unique_ptr, std::make_unique), and a multi-file CMake project with '
    'conditional test targets.',
    styles['body']
))

story.append(Paragraph(
    'The validation procedure requires only three commands after installing NDK Lite. First, '
    'the developer installs the Termux dependencies with "pkg install clang cmake ninja git". '
    'Second, the project is cloned with "git clone" or the source is obtained. Third, the build '
    'is executed with "ndk-lite-build ." from the project directory. If the toolchain, sysroot, '
    'and build integration are all functioning correctly, the command will produce '
    'libassimp_lite.so in the build-output directory without any errors. This end-to-end test '
    'validates the complete compilation pipeline from source files through CMake configuration, '
    'Clang compilation, LLD linking, and artifact collection.',
    styles['body']
))

# ═══════════════════════════════════════════════════════════════════════
# SECTION 11: DEVELOPMENT ROADMAP
# ═══════════════════════════════════════════════════════════════════════
story.append(CondPageBreak(H1_ORPHAN_THRESHOLD))
story.append(add_heading('11. Development Roadmap', 'h1', 0))

story.append(Paragraph(
    'NDK Lite follows an incremental development strategy where each version adds capabilities '
    'while maintaining backward compatibility with existing projects. The roadmap is structured '
    'into four major versions, each with a clear scope and deliverable set.',
    styles['body']
))

story.append(Spacer(1, 6))
t = make_table(
    ['Version', 'Focus', 'Key Deliverables'],
    [
        ['v1.0', 'Core Toolchain', 'C/C++ static/shared libraries, CMake + Ninja, JNI bridges, Termux packages, assimp_lite validation'],
        ['v2.0', 'Graphics APIs', 'OpenGL ES 2.0/3.0 headers, EGL context management, Vulkan API headers, shader compilation utilities'],
        ['v3.0', 'APK Builder', 'aapt2 resource compilation, d8 dexing, zipalign optimization, keystore signing, APK output'],
        ['v4.0', 'AAB Builder', 'bundletool integration, base module splitting, asset delivery configuration, Play Store readiness'],
    ],
    [0.10, 0.18, 0.72]
)
story.append(t)
story.append(Paragraph('<b>Table 4.</b> NDK Lite Development Roadmap', styles['caption']))

# ═══════════════════════════════════════════════════════════════════════
# SECTION 12: RISKS AND MITIGATION
# ═══════════════════════════════════════════════════════════════════════
story.append(CondPageBreak(H1_ORPHAN_THRESHOLD))
story.append(add_heading('12. Technical Risks and Mitigation', 'h1', 0))

story.append(Paragraph(
    'Every engineering project faces risks. NDK Lite identifies the following technical risks '
    'with corresponding mitigation strategies to ensure project viability and developer confidence.',
    styles['body']
))

story.append(Spacer(1, 6))
t = make_table(
    ['Risk', 'Severity', 'Mitigation Strategy'],
    [
        ['Termux Clang ABI mismatch with Android bionic', 'High',
         'Validate symbol compatibility per API level; use --target flag for exact ABI matching; maintain compatibility test suite'],
        ['Incomplete sysroot headers causing compilation failures', 'High',
         'Multi-strategy sysroot generator with NDK extraction fallback; community-maintained header coverage matrix'],
        ['Android API level fragmentation (21-35)', 'Medium',
         'Default to API 26 (Android 8.0) with configurable --api flag; test against multiple API levels in CI'],
        ['Termux package updates breaking toolchain compatibility', 'Medium',
         'Pin minimum package versions in setup script; implement toolchain version detection and warning system'],
        ['Limited header coverage for niche Android APIs', 'Low',
         'Modular package system allows incremental header additions; community contributions via CONTRIBUTING.md'],
        ['Performance regression on low-end ARM64 devices', 'Low',
         'Ninja parallelism defaults to nproc; --jobs flag allows resource-constrained builds; minimal toolchain overhead'],
    ],
    [0.22, 0.10, 0.68]
)
story.append(t)
story.append(Paragraph('<b>Table 5.</b> Technical Risk Assessment and Mitigation', styles['caption']))

# ═══════════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════════
doc.multiBuild(story)
print(f"[OK] Architecture document generated: {output_path}")
