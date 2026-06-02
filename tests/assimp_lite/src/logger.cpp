// ============================================================================
// assimp_lite — Logger Implementation
// Copyright (c) 2024-2026 Project Tomorrow Inc.
// ============================================================================

#include "assimp_lite/logger.h"
#include <android/log.h>

namespace assimp_lite {

static log_level g_level = log_level::info;

void set_log_level(log_level level) {
    g_level = level;
}

void log_verbose(const std::string& msg) {
    if (g_level <= log_level::verbose) {
        __android_log_print(ANDROID_LOG_VERBOSE, "assimp_lite", "%s", msg.c_str());
    }
}

void log_info(const std::string& msg) {
    if (g_level <= log_level::info) {
        __android_log_print(ANDROID_LOG_INFO, "assimp_lite", "%s", msg.c_str());
    }
}

void log_warning(const std::string& msg) {
    if (g_level <= log_level::warning) {
        __android_log_print(ANDROID_LOG_WARN, "assimp_lite", "%s", msg.c_str());
    }
}

void log_error(const std::string& msg) {
    if (g_level <= log_level::error) {
        __android_log_print(ANDROID_LOG_ERROR, "assimp_lite", "%s", msg.c_str());
    }
}

} // namespace assimp_lite
