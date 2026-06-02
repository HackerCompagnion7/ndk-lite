#pragma once

#include <array>
#include <cstring>
#include <cmath>

namespace assimp_lite {
namespace math {

class mat4 {
public:
    // Column-major storage (OpenGL convention)
    // m[col][row]
    std::array<std::array<real_t, 4>, 4> m{};

    // Constructors
    mat4() { identity(); }

    explicit mat4(real_t s) {
        for (auto& col : m) col.fill(0);
        m[0][0] = m[1][1] = m[2][2] = m[3][3] = s;
    }

    // Element access (column, row)
    real_t& operator()(std::size_t col, std::size_t row) { return m[col][row]; }
    const real_t& operator()(std::size_t col, std::size_t row) const { return m[col][row]; }

    // Static factory methods
    static mat4 identity() {
        mat4 result;
        for (auto& col : result.m) col.fill(0);
        result.m[0][0] = result.m[1][1] = result.m[2][2] = result.m[3][3] = 1.0f;
        return result;
    }

    static mat4 translation(real_t tx, real_t ty, real_t tz) {
        mat4 result = identity();
        result.m[3][0] = tx;
        result.m[3][1] = ty;
        result.m[3][2] = tz;
        return result;
    }

    static mat4 scaling(real_t sx, real_t sy, real_t sz) {
        mat4 result;
        for (auto& col : result.m) col.fill(0);
        result.m[0][0] = sx;
        result.m[1][1] = sy;
        result.m[2][2] = sz;
        result.m[3][3] = 1.0f;
        return result;
    }

    static mat4 rotation_x(real_t angle_rad) {
        mat4 result = identity();
        real_t c = std::cos(angle_rad);
        real_t s = std::sin(angle_rad);
        result.m[1][1] = c;
        result.m[1][2] = s;
        result.m[2][1] = -s;
        result.m[2][2] = c;
        return result;
    }

    static mat4 rotation_y(real_t angle_rad) {
        mat4 result = identity();
        real_t c = std::cos(angle_rad);
        real_t s = std::sin(angle_rad);
        result.m[0][0] = c;
        result.m[0][2] = -s;
        result.m[2][0] = s;
        result.m[2][2] = c;
        return result;
    }

    static mat4 rotation_z(real_t angle_rad) {
        mat4 result = identity();
        real_t c = std::cos(angle_rad);
        real_t s = std::sin(angle_rad);
        result.m[0][1] = s;
        result.m[0][0] = c;
        result.m[1][0] = -s;
        result.m[1][1] = c;
        return result;
    }

    // Matrix multiplication
    mat4 operator*(const mat4& other) const {
        mat4 result;
        for (auto& col : result.m) col.fill(0);
        for (std::size_t c = 0; c < 4; ++c) {
            for (std::size_t r = 0; r < 4; ++r) {
                for (std::size_t k = 0; k < 4; ++k) {
                    result.m[c][r] += m[k][r] * other.m[c][k];
                }
            }
        }
        return result;
    }

    mat4& operator*=(const mat4& other) {
        *this = *this * other;
        return *this;
    }

    // Raw data access (column-major, suitable for OpenGL)
    const real_t* data() const { return &m[0][0]; }
    real_t* data() { return &m[0][0]; }

    // Comparison
    bool operator==(const mat4& other) const { return m == other.m; }
    bool operator!=(const mat4& other) const { return m != other.m; }
};

} // namespace math
} // namespace assimp_lite
