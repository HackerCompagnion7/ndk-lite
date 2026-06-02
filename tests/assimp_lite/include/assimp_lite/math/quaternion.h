#pragma once

#include <cmath>

namespace assimp_lite {
namespace math {

class quaternion {
public:
    real_t w, x, y, z;

    // Constructors
    quaternion() : w(1.0f), x(0.0f), y(0.0f), z(0.0f) {}
    quaternion(real_t w_, real_t x_, real_t y_, real_t z_)
        : w(w_), x(x_), y(y_), z(z_) {}

    // Factory: create from axis-angle representation
    static quaternion from_axis_angle(const vec3& axis, real_t angle_rad) {
        real_t half = angle_rad * 0.5f;
        real_t s = std::sin(half);
        vec3 n = axis.normalized();
        return quaternion(std::cos(half), n.x * s, n.y * s, n.z * s);
    }

    // Quaternion multiplication (Hamilton product)
    quaternion operator*(const quaternion& q) const {
        return quaternion(
            w * q.w - x * q.x - y * q.y - z * q.z,
            w * q.x + x * q.w + y * q.z - z * q.y,
            w * q.y - x * q.z + y * q.w + z * q.x,
            w * q.z + x * q.y - y * q.x + z * q.w
        );
    }

    quaternion& operator*=(const quaternion& q) {
        *this = *this * q;
        return *this;
    }

    // Methods
    real_t length() const {
        return std::sqrt(w * w + x * x + y * y + z * z);
    }

    quaternion normalized() const {
        real_t len = length();
        if (len > 0) {
            return quaternion(w / len, x / len, y / len, z / len);
        }
        return quaternion{};
    }

    // Convert to rotation matrix
    mat4 to_matrix() const {
        quaternion n = normalized();
        real_t xx = n.x * n.x, yy = n.y * n.y, zz = n.z * n.z;
        real_t xy = n.x * n.y, xz = n.x * n.z, yz = n.y * n.z;
        real_t wx = n.w * n.x, wy = n.w * n.y, wz = n.w * n.z;

        mat4 result = mat4::identity();
        result(0, 0) = 1.0f - 2.0f * (yy + zz);
        result(0, 1) = 2.0f * (xy + wz);
        result(0, 2) = 2.0f * (xz - wy);

        result(1, 0) = 2.0f * (xy - wz);
        result(1, 1) = 1.0f - 2.0f * (xx + zz);
        result(1, 2) = 2.0f * (yz + wx);

        result(2, 0) = 2.0f * (xz + wy);
        result(2, 1) = 2.0f * (yz - wx);
        result(2, 2) = 1.0f - 2.0f * (xx + yy);

        return result;
    }

    // Comparison
    bool operator==(const quaternion& q) const {
        return w == q.w && x == q.x && y == q.y && z == q.z;
    }
    bool operator!=(const quaternion& q) const { return !(*this == q); }
};

} // namespace math
} // namespace assimp_lite
