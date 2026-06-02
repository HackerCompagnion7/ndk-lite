# Contributing to NDK Lite

Thank you for your interest in contributing to NDK Lite! This document provides guidelines for contributing to the project.

## Code of Conduct

- Be respectful and professional
- Focus on constructive feedback
- Support fellow contributors

## How to Contribute

### Bug Reports

1. Search existing issues to avoid duplicates
2. Create a new issue with:
   - Device model and Android version
   - Termux version (`termux-info`)
   - NDK Lite version (`ndk-lite-cc --ndk-lite-version`)
   - Steps to reproduce
   - Expected vs. actual behavior
   - Relevant logs

### Feature Requests

1. Check the roadmap in README.md to see if it's already planned
2. Create an issue with the `feature` label
3. Describe the use case and expected behavior

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test on a real Termux ARM64 environment
5. Ensure all existing tests pass
6. Submit the PR with a clear description

## Development Setup

```bash
pkg install clang cmake ninja git llvm
git clone https://github.com/project-tomorrow/ndk-lite.git
cd ndk-lite
./scripts/ndk-lite-setup.sh
```

## Code Standards

### Shell Scripts

- Use `#!/data/data/com.termux/files/usr/bin/bash` shebang
- Always use `set -euo pipefail`
- Use meaningful variable names
- Include the NDK Lite header comment block
- Handle errors gracefully with informative messages

### CMake

- Minimum version: 3.22
- Use modern CMake (target-based)
- Export compile commands
- Use `CMAKE_TOOLCHAIN_FILE` for cross-compilation

### C/C++ Headers

- Use `#pragma once` for include guards
- Use C++17 standard
- Follow the project namespace conventions
- Document public API with comments

### Commit Messages

Format:
```
type(scope): description

[optional body]
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `build`

Examples:
- `feat(toolchain): add API level 33 support`
- `fix(sysroot): correct EGL header stubs`
- `docs(readme): update quick start guide`

## Testing

Before submitting a PR, verify:

1. **Toolchain test**: Compile a simple C and C++ file
   ```bash
   echo 'int main(){return 0;}' > test.c
   ndk-lite-cc test.c -o test
   ```

2. **Build test**: Create and build a new project
   ```bash
   ndk-lite-new cpp test-project
   cd test-project
   ndk-lite-build .
   ```

3. **assimp_lite test**: Build the validation project
   ```bash
   cd tests/assimp_lite
   ndk-lite-build .
   ```

## Architecture Notes

When contributing, keep in mind the core design principles:

- **ARM64 Native**: Everything must run on ARM64. No x86_64 binaries.
- **Termux-First**: Use Termux's package ecosystem. Don't bundle what Termux provides.
- **Minimal Sysroot**: Only include headers that Termux doesn't provide. Use linker scripts for system libraries.
- **No Emulation**: No QEMU, no binfmt_misc. Pure native ARM64.

---

*Copyright © 2024-2026 Project Tomorrow Inc.*
