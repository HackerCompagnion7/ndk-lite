#pragma once

#include <string>
#include <variant>
#include <vector>
#include <unordered_map>

#include <assimp_lite/config.h>
#include <assimp_lite/math/vec3.h>

namespace assimp_lite {

// Property value can hold various types
using property_value = std::variant<
    int32_t,
    real_t,
    std::string,
    vec3
>;

// Property type enum for querying
enum class property_type {
    integer,
    floating,
    string,
    vector3
};

class material {
public:
    std::string name;

    // Properties map: key -> value
    std::unordered_map<std::string, property_value> properties;

    // Constructors
    material() = default;
    explicit material(std::string name_) : name(std::move(name_)) {}

    // Set a property
    template <typename T>
    void set_property(const std::string& key, T&& value) {
        properties[key] = std::forward<T>(value);
    }

    // Get a property by type; returns nullptr if type mismatches or key missing
    template <typename T>
    const T* get_property(const std::string& key) const {
        auto it = properties.find(key);
        if (it == properties.end()) return nullptr;
        return std::get_if<T>(&it->second);
    }

    // Check if property exists
    bool has_property(const std::string& key) const {
        return properties.find(key) != properties.end();
    }

    // Get the type of a property
    property_type get_property_type(const std::string& key) const {
        auto it = properties.find(key);
        if (it == properties.end()) {
            // Return a default; caller should check has_property first
            return property_type::integer;
        }
        const auto& val = it->second;
        if (std::holds_alternative<int32_t>(val)) return property_type::integer;
        if (std::holds_alternative<real_t>(val)) return property_type::floating;
        if (std::holds_alternative<std::string>(val)) return property_type::string;
        if (std::holds_alternative<vec3>(val)) return property_type::vector3;
        return property_type::integer;
    }

    // Convenience accessors for common material properties
    vec3 get_diffuse_color() const {
        auto* col = get_property<vec3>("diffuse_color");
        return col ? *col : vec3{0.8f, 0.8f, 0.8f};
    }

    vec3 get_specular_color() const {
        auto* col = get_property<vec3>("specular_color");
        return col ? *col : vec3{0.0f, 0.0f, 0.0f};
    }

    vec3 get_ambient_color() const {
        auto* col = get_property<vec3>("ambient_color");
        return col ? *col : vec3{0.1f, 0.1f, 0.1f};
    }

    real_t get_shininess() const {
        auto* s = get_property<real_t>("shininess");
        return s ? *s : 0.0f;
    }

    std::string get_diffuse_texture() const {
        auto* tex = get_property<std::string>("diffuse_texture");
        return tex ? *tex : "";
    }
};

} // namespace assimp_lite
