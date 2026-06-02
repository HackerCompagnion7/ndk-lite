// ============================================================================
// assimp_lite — Material Implementation
// Copyright (c) 2024-2026 Project Tomorrow Inc.
// ============================================================================

#include "assimp_lite/material.h"

namespace assimp_lite {

material::material() : name_("default") {}

void material::set_name(const std::string& n) {
    name_ = n;
}

const std::string& material::name() const {
    return name_;
}

void material::set_property(const std::string& key, const property_value& value) {
    properties_[key] = value;
}

bool material::has_property(const std::string& key) const {
    return properties_.find(key) != properties_.end();
}

std::optional<material::property_value> material::get_property(const std::string& key) const {
    auto it = properties_.find(key);
    if (it != properties_.end()) {
        return it->second;
    }
    return std::nullopt;
}

} // namespace assimp_lite
