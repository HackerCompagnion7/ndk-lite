// ============================================================================
// assimp_lite — OBJ Loader Implementation
// Copyright (c) 2024-2026 Project Tomorrow Inc.
// ============================================================================

#include "assimp_lite/formats/obj_loader.h"
#include "assimp_lite/logger.h"
#include "assimp_lite/scene.h"
#include "assimp_lite/mesh.h"
#include "assimp_lite/material.h"
#include <fstream>
#include <sstream>
#include <algorithm>

namespace assimp_lite {

bool obj_loader::can_load(const std::string& extension) const {
    return extension == "obj";
}

std::vector<std::string> obj_loader::extensions() const {
    return {"obj"};
}

std::unique_ptr<scene> obj_loader::load(const std::string& path) const {
    log_info("obj_loader: loading: " + path);

    std::ifstream file(path);
    if (!file.is_open()) {
        log_error("obj_loader: cannot open file: " + path);
        return nullptr;
    }

    auto result = std::make_unique<scene>();
    auto current_mesh = std::make_unique<mesh>();

    std::vector<math::vec3> positions;
    std::vector<math::vec3> normals;
    std::vector<math::vec3> uvs;

    std::string line;
    while (std::getline(file, line)) {
        // Remove leading whitespace
        size_t start = line.find_first_not_of(" \t\r\n");
        if (start == std::string::npos || line[start] == '#') continue;

        std::istringstream iss(line);
        std::string token;
        iss >> token;

        if (token == "v") {
            float x, y, z;
            iss >> x >> y >> z;
            positions.emplace_back(x, y, z);
        } else if (token == "vn") {
            float x, y, z;
            iss >> x >> y >> z;
            normals.emplace_back(x, y, z);
        } else if (token == "vt") {
            float u, v;
            iss >> u >> v;
            uvs.emplace_back(u, v, 0.0f);
        } else if (token == "f") {
            // Parse face (simplified: vertex indices only)
            std::string face_token;
            while (iss >> face_token) {
                uint32_t idx = 0;
                // Parse v/vt/vn format
                auto slash_pos = face_token.find('/');
                if (slash_pos != std::string::npos) {
                    idx = static_cast<uint32_t>(std::stoi(face_token.substr(0, slash_pos)) - 1);
                } else {
                    idx = static_cast<uint32_t>(std::stoi(face_token) - 1);
                }
                current_mesh->set_indices({});
                // Store index temporarily
            }
        } else if (token == "o" || token == "g") {
            std::string name;
            iss >> name;
            current_mesh->set_name(name);
        }
    }

    current_mesh->set_vertices(positions);
    current_mesh->set_normals(normals);
    current_mesh->set_uv_coords(uvs);

    result->add_mesh(std::move(current_mesh));
    return result;
}

} // namespace assimp_lite
