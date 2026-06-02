// ============================================================================
// assimp_lite — Vector3 Implementation
// Copyright (c) 2024-2026 Project Tomorrow Inc.
// ============================================================================

#include "assimp_lite/math/vec3.h"
#include <cmath>

namespace assimp_lite {
namespace math {

vec3::vec3() : x(0.0f), y(0.0f), z(0.0f) {}

vec3::vec3(float x_, float y_, float z_) : x(x_), y(y_), z(z_) {}

vec3 vec3::operator+(const vec3& other) const {
    return vec3(x + other.x, y + other.y, z + other.z);
}

vec3 vec3::operator-(const vec3& other) const {
    return vec3(x - other.x, y - other.y, z - other.z);
}

vec3 vec3::operator*(float scalar) const {
    return vec3(x * scalar, y * scalar, z * scalar);
}

vec3 vec3::operator/(float scalar) const {
    float inv = 1.0f / scalar;
    return vec3(x * inv, y * inv, z * inv);
}

float vec3::length() const {
    return std::sqrt(x * x + y * y + z * z);
}

vec3 vec3::normalized() const {
    float len = length();
    if (len > 0.00001f) {
        return *this / len;
    }
    return vec3(0.0f, 0.0f, 0.0f);
}

float vec3::dot(const vec3& other) const {
    return x * other.x + y * other.y + z * other.z;
}

vec3 vec3::cross(const vec3& other) const {
    return vec3(
        y * other.z - z * other.y,
        z * other.x - x * other.z,
        x * other.y - y * other.x
    );
}

} // namespace math
} // namespace assimp_lite
