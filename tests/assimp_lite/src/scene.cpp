// ============================================================================
// assimp_lite — Scene Implementation
// Copyright (c) 2024-2026 Project Tomorrow Inc.
// ============================================================================

#include "assimp_lite/scene.h"
#include "assimp_lite/logger.h"
#include <android/log.h>

namespace assimp_lite {

scene::scene() : root_node_(nullptr), loaded_(false) {
    log_info("scene: created");
}

scene::~scene() {
    clear();
}

void scene::clear() {
    meshes_.clear();
    materials_.clear();
    root_node_.reset();
    loaded_ = false;
    log_info("scene: cleared");
}

bool scene::is_loaded() const {
    return loaded_;
}

size_t scene::mesh_count() const {
    return meshes_.size();
}

size_t scene::material_count() const {
    return materials_.size();
}

mesh* scene::get_mesh(size_t index) {
    if (index < meshes_.size()) {
        return meshes_[index].get();
    }
    return nullptr;
}

material* scene::get_material(size_t index) {
    if (index < materials_.size()) {
        return materials_[index].get();
    }
    return nullptr;
}

void scene::add_mesh(std::unique_ptr<mesh> m) {
    meshes_.push_back(std::move(m));
}

void scene::add_material(std::unique_ptr<material> mat) {
    materials_.push_back(std::move(mat));
}

void scene::set_root_node(std::unique_ptr<scene_node> node) {
    root_node_ = std::move(node);
}

scene_node* scene::root_node() {
    return root_node_.get();
}

} // namespace assimp_lite
