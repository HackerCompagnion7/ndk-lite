# NDK Lite

**Android ARM64 Native Development Toolkit for Termux**

*by Project Tomorrow Inc.*

---

## What is NDK Lite?

NDK Lite is a lightweight alternative to the official Android NDK, designed to run **natively on Android ARM64 devices** through Termux. It enables you to compile C/C++ native libraries and applications directly from your phone — no PC, no Android Studio, no x86_64 binaries required.

```
Termux ARM64
      ↓
NDK Lite
      ↓
CMake + Ninja
      ↓
LLVM ARM64 (Termux Clang)
      ↓
Android Native Libraries (.a / .so)
```

## Quick Start

### 1. Install Termux Dependencies

```bash
pkg install clang cmake ninja git
```

### 2. Clone and Setup NDK Lite

```bash
git clone https://github.com/project-tomorrow/ndk-lite.git
cd ndk-lite
chmod +x scripts/*.sh src/toolchain/*.sh src/sysroot/*.sh
./scripts/ndk-lite-setup.sh
```

### 3. Create a Project

```bash
ndk-lite-new cpp mylib
cd mylib
```

### 4. Build

```bash
ndk-lite-build .
```

Output goes to `build-output/` — you'll find `libmylib.so` (or `.a`).

## Commands

| Command | Description |
|---------|-------------|
| `ndk-lite-setup` | Initialize NDK Lite environment |
| `ndk-lite-new <type> <name>` | Create new project (cpp, c, jni, opengl) |
| `ndk-lite-build [dir]` | Build project |
| `ndk-lite-cc <file.c>` | Compile C file with Android target |
| `ndk-lite-cxx <file.cpp>` | Compile C++ file with Android target |
| `ndk-lite-ld <options>` | Link with Android LLD |
| `ndk-lite-ar rcs <lib.a> <.o>` | Create static library archive |

## Build Options

```bash
ndk-lite-build --type=static .          # Static library (.a)
ndk-lite-build --type=shared .          # Shared library (.so) [default]
ndk-lite-build --debug .                # Debug build
ndk-lite-build --api=28 .               # Target Android API 28
ndk-lite-build --stl=c++_shared .       # Use shared C++ STL
ndk-lite-build --clean .                # Clean build
ndk-lite-build --verbose .              # Verbose output
ndk-lite-build -j8 .                    # 8 parallel jobs
ndk-lite-build --gen=make .             # Use Make instead of Ninja
```

## Project Templates

| Type | Description | Output |
|------|-------------|--------|
| `cpp` | C++ library | `lib<name>.so` / `.a` |
| `c` | C library | `lib<name>.so` / `.a` |
| `jni` | JNI bridge | `lib<name>.so` with JNI exports |
| `opengl` | OpenGL ES 2.0 renderer | `lib<name>.so` with EGL/GLES2 |

## Architecture

NDK Lite consists of 5 layers:

1. **Toolchain Layer** — Clang/LLVM wrappers using Termux's native ARM64 compilers
2. **Sysroot Layer** — Android headers and library stubs
3. **Build Integration Layer** — CMake toolchain file and build automation
4. **Package Layer** — Termux .deb package definitions
5. **Laragon Integration Layer** — JSON bridge for Laragon OS UI

### Directory Structure

```
ndk-lite/
├── cmake/
│   └── android-arm64-v8a.cmake    # CMake toolchain file
├── scripts/
│   ├── ndk-lite-build.sh          # Main build command
│   ├── ndk-lite-new.sh            # Project scaffolding
│   └── ndk-lite-setup.sh          # Environment setup
├── src/
│   ├── toolchain/
│   │   ├── ndk-lite-cc.sh         # C compiler wrapper
│   │   ├── ndk-lite-cxx.sh        # C++ compiler wrapper
│   │   ├── ndk-lite-ld.sh         # Linker wrapper
│   │   ├── ndk-lite-ar.sh         # Archiver wrapper
│   │   └── ndk-lite-ranlib.sh     # Ranlib wrapper
│   ├── sysroot/
│   │   └── generate_sysroot.sh    # Sysroot generator
│   ├── package/
│   │   └── build-packages.sh      # Package builder
│   └── laragon/
│       └── ndk-lite-laragon-bridge.sh  # Laragon OS bridge
├── sysroot/                        # Generated sysroot
│   ├── usr/include/                # Android headers
│   └── usr/lib/                    # Library stubs
├── tests/
│   └── assimp_lite/               # Validation test project
├── LICENSE                         # Apache 2.0
└── README.md
```

## How It Works

Unlike the official Android NDK which ships x86_64 host tools, NDK Lite uses Termux's native ARM64 LLVM/Clang toolchain and injects Android target flags:

- `--target=aarch64-linux-android26` — Targets Android ARM64 API 26
- `--sysroot=<ndk-lite>/sysroot` — Uses Android-specific headers/stubs
- `-fuse-ld=lld` — Uses LLVM's LLD linker
- Android system libraries are referenced via linker scripts pointing to `/system/lib64/`

This means **no QEMU, no binfmt, no x86_64 emulation** — everything runs natively on ARM64.

## Validation

NDK Lite validates against a real C++ project (`assimp_lite`) that includes:

- Math types (vec3, mat4, quaternion)
- Scene graph with mesh/material management
- Multiple format loaders (OBJ, STL)
- Android logging integration
- CMake with multiple targets

```bash
cd tests/assimp_lite
ndk-lite-build .
# Should produce: build-output/libassimp_lite.so
```

## Supported Targets (v1.0)

- ✅ C static libraries (.a)
- ✅ C shared libraries (.so)
- ✅ C++ static libraries (.a)
- ✅ C++ shared libraries (.so)
- ✅ CMake + Ninja builds
- ✅ JNI bridge libraries
- ✅ Android logging (liblog)
- ✅ API level 26+

## Roadmap

| Version | Features |
|---------|----------|
| **v1.0** | Core toolchain, sysroot, C/C++ builds, JNI |
| **v2.0** | OpenGL ES, EGL, Vulkan headers |
| **v3.0** | APK Builder (aapt2, d8, zipalign) |
| **v4.0** | AAB Builder (bundletool) |

## Requirements

- Android device with ARM64 (aarch64) processor
- [Termux](https://termux.dev/) installed
- Termux packages: `clang`, `cmake`, `ninja`, `git`
- Android 8.0 (API 26) or higher

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

Apache License 2.0 — See [LICENSE](LICENSE)

---

*NDK Lite — Native development on Android, for Android.*
*Copyright © 2024-2026 Project Tomorrow Inc.*
