// ============================================================================
// assimp_lite — Mesh Implementation
// Copyright (c) 2024-2026 Project Tomorrow Inc.
// ============================================================================

#include "assimp_lite/mesh.h"

namespace assimp_lite {

mesh::mesh()
    : primitive_type_(primitive_type::triangles)
    , material_index_(0)
    , name_("unnamed")
{}

void mesh::set_vertices(const std::vector<math::vec3>& verts) {
    vertices_ = verts;
}

void mesh::set_normals(const std::vector<math::vec3>& norms) {
    normals_ = norms;
}

void mesh::set_uv_coords(const std::vector<math::vec3>& uvs) {
    uv_coords_ = uvs;
}

void mesh::set_indices(const std::vector<uint32_t>& idx) {
    indices_ = idx;
}

void mesh::set_name(const std::string& n) {
    name_ = n;
}

void mesh::set_material_index(size_t idx) {
    material_index_ = idx;
}

size_t mesh::vertex_count() const {
    return vertices_.size();
}

size_t mesh::index_count() const {
    return indices_.size();
}

float mesh::compute_bounding_radius() const {
    float max_sq = 0.0f;
    for (const auto& v : vertices_) {
        float d = v.dot(v);
        if (d > max_sq) max_sq = d;
    }
    return std::sqrt(max_sq);
}

} // namespace assimp_lite
