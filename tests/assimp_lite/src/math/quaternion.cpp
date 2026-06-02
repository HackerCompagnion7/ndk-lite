// ============================================================================
// assimp_lite — Quaternion Implementation
// Copyright (c) 2024-2026 Project Tomorrow Inc.
// ============================================================================

#include "assimp_lite/math/quaternion.h"
#include <cmath>

namespace assimp_lite {
namespace math {

quaternion::quaternion() : w(1.0f), x(0.0f), y(0.0f), z(0.0f) {}

quaternion::quaternion(float w_, float x_, float y_, float z_)
    : w(w_), x(x_), y(y_), z(z_) {}

quaternion quaternion::from_axis_angle(const vec3& axis, float angle_rad) {
    float half = angle_rad * 0.5f;
    float s = std::sin(half);
    vec3 n = axis.normalized();
    return quaternion(std::cos(half), n.x * s, n.y * s, n.z * s);
}

quaternion quaternion::operator*(const quaternion& other) const {
    return quaternion(
        w * other.w - x * other.x - y * other.y - z * other.z,
        w * other.x + x * other.w + y * other.z - z * other.y,
        w * other.y - x * other.z + y * other.w + z * other.x,
        w * other.z + x * other.y - y * other.x + z * other.w
    );
}

float quaternion::length() const {
    return std::sqrt(w * w + x * x + y * y + z * z);
}

quaternion quaternion::normalized() const {
    float len = length();
    if (len > 0.00001f) {
        float inv = 1.0f / len;
        return quaternion(w * inv, x * inv, y * inv, z * inv);
    }
    return quaternion();
}

mat4 quaternion::to_matrix() const {
    mat4 result = mat4::identity();
    float* m = result.data();

    float xx = x * x, yy = y * y, zz = z * z;
    float xy = x * y, xz = x * z, yz = y * z;
    float wx = w * x, wy = w * y, wz = w * z;

    // Column-major layout
    m[0]  = 1.0f - 2.0f * (yy + zz);
    m[1]  = 2.0f * (xy + wz);
    m[2]  = 2.0f * (xz - wy);
    m[4]  = 2.0f * (xy - wz);
    m[5]  = 1.0f - 2.0f * (xx + zz);
    m[6]  = 2.0f * (yz + wx);
    m[8]  = 2.0f * (xz + wy);
    m[9]  = 2.0f * (yz - wx);
    m[10] = 1.0f - 2.0f * (xx + yy);

    return result;
}

} // namespace math
} // namespace assimp_lite
