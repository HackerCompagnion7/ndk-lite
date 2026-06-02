#pragma once

#include <vector>
#include <string>
#include <memory>
#include <optional>

#include <assimp_lite/config.h>
#include <assimp_lite/math/mat4.h>
#include <assimp_lite/mesh.h>
#include <assimp_lite/material.h>

namespace assimp_lite {

// A node in the scene graph
struct scene_node {
    std::string name;
    math::mat4 transform = math::mat4::identity();
    std::vector<std::unique_ptr<scene_node>> children;

    // Optional index into the scene's mesh array (-1 / nullopt if this node has no mesh)
    std::optional<std::size_t> mesh_index;

    // Default constructor
    scene_node() = default;

    // Constructor with name
    explicit scene_node(std::string name_) : name(std::move(name_)) {}

    // Add a child node; returns reference to the added child
    scene_node& add_child(std::unique_ptr<scene_node> child) {
        auto& ref = *child;
        children.push_back(std::move(child));
        return ref;
    }

    // Create and add a child node
    scene_node& create_child(const std::string& child_name) {
        auto child = std::make_unique<scene_node>(child_name);
        return add_child(std::move(child));
    }

    // Find a child by name (recursive)
    scene_node* find_child(const std::string& child_name) {
        for (auto& child : children) {
            if (child->name == child_name) return child.get();
            auto* found = child->find_child(child_name);
            if (found) return found;
        }
        return nullptr;
    }

    const scene_node* find_child(const std::string& child_name) const {
        for (const auto& child : children) {
            if (child->name == child_name) return child.get();
            const auto* found = child->find_child(child_name);
            if (found) return found;
        }
        return nullptr;
    }

    // Check if this node has a mesh attached
    bool has_mesh() const { return mesh_index.has_value(); }
};

// Scene holds all loaded data
class scene {
public:
    std::vector<mesh> meshes;
    std::vector<material> materials;

    // Root node of the scene graph
    std::unique_ptr<scene_node> root_node;

    // Constructors
    scene() : root_node(std::make_unique<scene_node>("root")) {}
    ~scene() = default;

    // Move-only (unique_ptr ownership)
    scene(scene&&) = default;
    scene& operator=(scene&&) = default;
    scene(const scene&) = delete;
    scene& operator=(const scene&) = delete;

    // Accessors
    bool empty() const { return meshes.empty() && materials.empty(); }
    std::size_t mesh_count() const { return meshes.size(); }
    std::size_t material_count() const { return materials.size(); }

    // Add a mesh, returns its index
    std::size_t add_mesh(mesh m) {
        std::size_t idx = meshes.size();
        meshes.push_back(std::move(m));
        return idx;
    }

    // Add a material, returns its index
    std::size_t add_material(material mat) {
        std::size_t idx = materials.size();
        materials.push_back(std::move(mat));
        return idx;
    }

    // Get mesh by index (nullptr if out of bounds)
    mesh* get_mesh(std::size_t index) {
        return index < meshes.size() ? &meshes[index] : nullptr;
    }
    const mesh* get_mesh(std::size_t index) const {
        return index < meshes.size() ? &meshes[index] : nullptr;
    }

    // Get material by index (nullptr if out of bounds)
    material* get_material(std::size_t index) {
        return index < materials.size() ? &materials[index] : nullptr;
    }
    const material* get_material(std::size_t index) const {
        return index < materials.size() ? &materials[index] : nullptr;
    }
};

} // namespace assimp_lite
