#pragma once

#include <vector>
#include <string>
#include <memory>
#include <functional>

#include <assimp_lite/config.h>
#include <assimp_lite/scene.h>

namespace assimp_lite {

// Forward declaration of format_loader base class
class format_loader;

// Alias for loader factory function
using loader_factory = std::function<std::unique_ptr<format_loader>()>;

// Base class for format-specific loaders
class format_loader {
public:
    virtual ~format_loader() = default;

    // Check if this loader can handle the given file extension
    virtual bool can_load(const std::string& extension) const = 0;

    // Load a file and populate the scene
    virtual bool load(const std::string& filepath, scene& out_scene) = 0;

    // Get the file extensions this loader supports (e.g., {"obj", "obj.gz"})
    virtual std::vector<std::string> extensions() const = 0;
};

// Main importer class
class importer {
public:
    importer();
    ~importer();

    // Move-only
    importer(importer&&) noexcept;
    importer& operator=(importer&&) noexcept;
    importer(const importer&) = delete;
    importer& operator=(const importer&) = delete;

    // Load a file from disk, returning the parsed scene
    // Returns nullptr on failure
    std::unique_ptr<scene> load_file(const std::string& filepath);

    // Register a custom format loader
    void register_loader(loader_factory factory);

    // Get all supported file extensions across registered loaders
    std::vector<std::string> supported_extensions() const;

private:
    class impl;
    std::unique_ptr<impl> pimpl_;
};

} // namespace assimp_lite
