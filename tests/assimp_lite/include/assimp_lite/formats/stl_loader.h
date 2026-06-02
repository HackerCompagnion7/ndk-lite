#pragma once

#include <string>
#include <vector>
#include <memory>

#include <assimp_lite/importer.h>
#include <assimp_lite/scene.h>

namespace assimp_lite {

// STL format loader — implements format_loader interface
// Supports both ASCII and binary STL formats
class stl_loader : public format_loader {
public:
    stl_loader() = default;
    ~stl_loader() override = default;

    // Check if this loader can handle the given extension
    bool can_load(const std::string& extension) const override;

    // Load an STL file into the scene
    bool load(const std::string& filepath, scene& out_scene) override;

    // Supported extensions: {"stl"}
    std::vector<std::string> extensions() const override;

private:
    // Internal parsing helpers (declarations for .cpp implementations)
    bool load_ascii(const std::string& filepath, scene& out_scene);
    bool load_binary(const std::string& filepath, scene& out_scene);

    // Detect whether an STL file is ASCII or binary
    bool is_ascii(const std::string& filepath) const;

    // Parse a single ASCII STL facet
    bool parse_facet(const std::vector<std::string>& lines,
                     std::size_t& current_line,
                     vec3& out_normal,
                     vec3& out_v0,
                     vec3& out_v1,
                     vec3& out_v2);
};

} // namespace assimp_lite
