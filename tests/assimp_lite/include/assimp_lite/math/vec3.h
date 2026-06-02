#pragma once

#include <cmath>
#include <array>
#include <ostream>

namespace assimp_lite {
namespace math {

class vec3 {
public:
    union {
        struct { real_t x, y, z; };
        std::array<real_t, 3> data{};
    };

    // Constructors
    vec3() : x(0), y(0), z(0) {}
    vec3(real_t x_, real_t y_, real_t z_) : x(x_), y(y_), z(z_) {}
    explicit vec3(real_t s) : x(s), y(s), z(s) {}

    // Element access
    real_t& operator[](std::size_t i) { return data[i]; }
    const real_t& operator[](std::size_t i) const { return data[i]; }

    // Arithmetic operators
    vec3 operator+(const vec3& v) const { return {x + v.x, y + v.y, z + v.z}; }
    vec3 operator-(const vec3& v) const { return {x - v.x, y - v.y, z - v.z}; }
    vec3 operator*(real_t s) const { return {x * s, y * s, z * s}; }
    vec3 operator/(real_t s) const { return {x / s, y / s, z / s}; }

    vec3 operator*(const vec3& v) const { return {x * v.x, y * v.y, z * v.z}; }
    vec3 operator/(const vec3& v) const { return {x / v.x, y / v.y, z / v.z}; }

    vec3 operator-() const { return {-x, -y, -z}; }

    // Compound assignment
    vec3& operator+=(const vec3& v) { x += v.x; y += v.y; z += v.z; return *this; }
    vec3& operator-=(const vec3& v) { x -= v.x; y -= v.y; z -= v.z; return *this; }
    vec3& operator*=(real_t s) { x *= s; y *= s; z *= s; return *this; }
    vec3& operator/=(real_t s) { x /= s; y /= s; z /= s; return *this; }

    // Methods
    real_t length() const { return std::sqrt(x * x + y * y + z * z); }
    real_t length_squared() const { return x * x + y * y + z * z; }

    vec3 normalized() const {
        real_t len = length();
        if (len > 0) return *this / len;
        return vec3{};
    }

    // Static functions
    static real_t dot(const vec3& a, const vec3& b) {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }

    static vec3 cross(const vec3& a, const vec3& b) {
        return {
            a.y * b.z - a.z * b.y,
            a.z * b.x - a.x * b.z,
            a.x * b.y - a.y * b.x
        };
    }

    // Comparison
    bool operator==(const vec3& v) const { return x == v.x && y == v.y && z == v.z; }
    bool operator!=(const vec3& v) const { return !(*this == v); }
};

// Free operator for scalar * vec3
inline vec3 operator*(real_t s, const vec3& v) { return v * s; }

// Stream output
inline std::ostream& operator<<(std::ostream& os, const vec3& v) {
    return os << "vec3(" << v.x << ", " << v.y << ", " << v.z << ")";
}

} // namespace math
} // namespace assimp_lite
