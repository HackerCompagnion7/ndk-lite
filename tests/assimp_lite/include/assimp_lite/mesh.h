#pragma once

#include <vector>
#include <string>
#include <cstdint>
#include <cmath>
#include <algorithm>

#include <assimp_lite/config.h>
#include <assimp_lite/math/vec3.h>

namespace assimp_lite {

class mesh {
public:
    std::string name;

    // Geometry data
    std::vector<vec3> vertices;
    std::vector<vec3> normals;
    std::vector<vec3> uv_coords;   // using vec3 for UVs; z is unused (or used for UVW)
    std::vector<uint32_t> indices;

    // Default constructor
    mesh() = default;

    // Constructor with name
    explicit mesh(std::string name_) : name(std::move(name_)) {}

    // Compute the bounding radius of the mesh based on vertex positions
    real_t compute_bounding_radius() const {
        if (vertices.empty()) return 0.0f;

        vec3 center{0, 0, 0};
        for (const auto& v : vertices) {
            center += v;
        }
        center = center / static_cast<real_t>(vertices.size());

        real_t max_dist = 0.0f;
        for (const auto& v : vertices) {
            real_t dist = (v - center).length();
            max_dist = std::max(max_dist, dist);
        }
        return max_dist;
    }

    // Utility
    bool has_normals() const { return !normals.empty(); }
    bool has_uv_coords() const { return !uv_coords.empty(); }
    bool has_indices() const { return !indices.empty(); }
    std::size_t vertex_count() const { return vertices.size(); }
    std::size_t index_count() const { return indices.size(); }
    std::size_t triangle_count() const { return indices.size() / 3; }
};

} // namespace assimp_lite
