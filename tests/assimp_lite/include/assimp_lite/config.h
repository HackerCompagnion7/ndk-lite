#pragma once

#include <cstdint>

namespace assimp_lite {

// Library version macros
#define ASSIMP_LITE_VERSION_MAJOR 1
#define ASSIMP_LITE_VERSION_MINOR 0
#define ASSIMP_LITE_VERSION_PATCH 0
#define ASSIMP_LITE_VERSION \
    ((ASSIMP_LITE_VERSION_MAJOR * 10000) + \
     (ASSIMP_LITE_VERSION_MINOR * 100) + \
     (ASSIMP_LITE_VERSION_PATCH))

#define ASSIMP_LITE_VERSION_STRING "1.0.0"

// Compile options
#ifndef ASSIMP_LITE_USE_DOUBLE_PRECISION
#define ASSIMP_LITE_USE_DOUBLE_PRECISION 0
#endif

#ifndef ASSIMP_LITE_ENABLE_THREADS
#define ASSIMP_LITE_ENABLE_THREADS 0
#endif

#ifndef ASSIMP_LITE_ENABLE_LOGGING
#define ASSIMP_LITE_ENABLE_LOGGING 1
#endif

#ifndef ASSIMP_LITE_MAX_MESHES_PER_SCENE
#define ASSIMP_LITE_MAX_MESHES_PER_SCENE 1024
#endif

#ifndef ASSIMP_LITE_MAX_MATERIALS_PER_SCENE
#define ASSIMP_LITE_MAX_MATERIALS_PER_SCENE 512
#endif

// Precision type alias
#if ASSIMP_LITE_USE_DOUBLE_PRECISION
using real_t = double;
#else
using real_t = float;
#endif

} // namespace assimp_lite
