#pragma once

#include <string>
#include <vector>
#include <memory>

#include <assimp_lite/importer.h>
#include <assimp_lite/scene.h>

namespace assimp_lite {

// OBJ format loader — implements format_loader interface
class obj_loader : public format_loader {
public:
    obj_loader() = default;
    ~obj_loader() override = default;

    // Check if this loader can handle the given extension
    bool can_load(const std::string& extension) const override;

    // Load an OBJ file into the scene
    bool load(const std::string& filepath, scene& out_scene) override;

    // Supported extensions: {"obj"}
    std::vector<std::string> extensions() const override;

private:
    // Internal parsing helpers (declarations for .cpp implementations)
    bool parse_vertex_line(const std::string& line, vec3& out_vertex);
    bool parse_normal_line(const std::string& line, vec3& out_normal);
    bool parse_uv_line(const std::string& line, vec3& out_uv);
    bool parse_face_line(const std::string& line,
                         std::vector<uint32_t>& out_indices,
                         std::vector<uint32_t>& out_normal_indices,
                         std::vector<uint32_t>& out_uv_indices);
    bool parse_mtl_lib(const std::string& line, scene& out_scene);
    bool parse_usemtl(const std::string& line, scene& out_scene);
};

} // namespace assimp_lite
