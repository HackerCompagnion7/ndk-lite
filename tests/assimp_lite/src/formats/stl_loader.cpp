// ============================================================================
// assimp_lite — STL Loader Implementation
// Copyright (c) 2024-2026 Project Tomorrow Inc.
// ============================================================================

#include "assimp_lite/formats/stl_loader.h"
#include "assimp_lite/logger.h"
#include "assimp_lite/scene.h"
#include "assimp_lite/mesh.h"
#include <fstream>
#include <cstring>

namespace assimp_lite {

bool stl_loader::can_load(const std::string& extension) const {
    return extension == "stl";
}

std::vector<std::string> stl_loader::extensions() const {
    return {"stl"};
}

std::unique_ptr<scene> stl_loader::load(const std::string& path) const {
    log_info("stl_loader: loading: " + path);

    std::ifstream file(path, std::ios::binary);
    if (!file.is_open()) {
        log_error("stl_loader: cannot open file: " + path);
        return nullptr;
    }

    // Read header (80 bytes)
    char header[80];
    file.read(header, 80);

    auto result = std::make_unique<scene>();
    auto mesh = std::make_unique<assimp_lite::mesh>();
    mesh->set_name("stl_mesh");

    // Read number of triangles
    uint32_t num_triangles = 0;
    file.read(reinterpret_cast<char*>(&num_triangles), 4);

    log_info("stl_loader: " + std::to_string(num_triangles) + " triangles");

    std::vector<math::vec3> vertices;
    std::vector<math::vec3> normals;
    std::vector<uint32_t> indices;

    for (uint32_t i = 0; i < num_triangles; ++i) {
        // Read normal
        float nx, ny, nz;
        file.read(reinterpret_cast<char*>(&nx), 4);
        file.read(reinterpret_cast<char*>(&ny), 4);
        file.read(reinterpret_cast<char*>(&nz), 4);

        // Read 3 vertices
        for (int v = 0; v < 3; ++v) {
            float vx, vy, vz;
            file.read(reinterpret_cast<char*>(&vx), 4);
            file.read(reinterpret_cast<char*>(&vy), 4);
            file.read(reinterpret_cast<char*>(&vz), 4);

            vertices.emplace_back(vx, vy, vz);
            normals.emplace_back(nx, ny, nz);
            indices.push_back(static_cast<uint32_t>(vertices.size() - 1));
        }

        // Skip attribute byte count
        uint16_t attr;
        file.read(reinterpret_cast<char*>(&attr), 2);
    }

    mesh->set_vertices(vertices);
    mesh->set_normals(normals);
    mesh->set_indices(indices);

    result->add_mesh(std::move(mesh));
    log_info("stl_loader: loaded successfully");

    return result;
}

} // namespace assimp_lite
