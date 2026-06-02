// ============================================================================
// assimp_lite — Importer Implementation
// Copyright (c) 2024-2026 Project Tomorrow Inc.
// ============================================================================

#include "assimp_lite/importer.h"
#include "assimp_lite/logger.h"
#include "assimp_lite/formats/obj_loader.h"
#include "assimp_lite/formats/stl_loader.h"
#include <algorithm>

namespace assimp_lite {

importer::importer() {
    // Register built-in format loaders
    register_loader(std::make_unique<obj_loader>());
    register_loader(std::make_unique<stl_loader>());
}

importer::~importer() = default;

void importer::register_loader(std::unique_ptr<format_loader> loader) {
    if (loader) {
        loaders_.push_back(std::move(loader));
    }
}

std::unique_ptr<scene> importer::load_file(const std::string& path) {
    log_info("importer: loading file: " + path);

    // Determine file extension
    auto dot_pos = path.rfind('.');
    if (dot_pos == std::string::npos) {
        log_error("importer: no file extension found");
        return nullptr;
    }

    std::string ext = path.substr(dot_pos + 1);
    std::transform(ext.begin(), ext.end(), ext.begin(), ::tolower);

    // Find appropriate loader
    format_loader* loader = nullptr;
    for (const auto& l : loaders_) {
        if (l->can_load(ext)) {
            loader = l.get();
            break;
        }
    }

    if (!loader) {
        log_error("importer: no loader found for extension: " + ext);
        return nullptr;
    }

    auto result = loader->load(path);
    if (result) {
        log_info("importer: loaded successfully: " + path);
    } else {
        log_error("importer: failed to load: " + path);
    }

    return result;
}

std::vector<std::string> importer::supported_extensions() const {
    std::vector<std::string> exts;
    for (const auto& l : loaders_) {
        auto le = l->extensions();
        exts.insert(exts.end(), le.begin(), le.end());
    }
    return exts;
}

} // namespace assimp_lite
