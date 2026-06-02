// ============================================================================
// assimp_lite — Matrix4x4 Implementation
// Copyright (c) 2024-2026 Project Tomorrow Inc.
// ============================================================================

#include "assimp_lite/math/mat4.h"
#include <cmath>
#include <cstring>

namespace assimp_lite {
namespace math {

mat4::mat4() {
    std::memset(m, 0, sizeof(m));
    m[0][0] = m[1][1] = m[2][2] = m[3][3] = 1.0f;
}

mat4 mat4::identity() {
    return mat4();
}

mat4 mat4::operator*(const mat4& other) const {
    mat4 result;
    for (int i = 0; i < 4; ++i) {
        for (int j = 0; j < 4; ++j) {
            result.m[i][j] = 0.0f;
            for (int k = 0; k < 4; ++k) {
                result.m[i][j] += m[i][k] * other.m[k][j];
            }
        }
    }
    return result;
}

mat4 mat4::translation(float tx, float ty, float tz) {
    mat4 result = identity();
    result.m[3][0] = tx;
    result.m[3][1] = ty;
    result.m[3][2] = tz;
    return result;
}

mat4 mat4::scaling(float sx, float sy, float sz) {
    mat4 result;
    std::memset(result.m, 0, sizeof(result.m));
    result.m[0][0] = sx;
    result.m[1][1] = sy;
    result.m[2][2] = sz;
    result.m[3][3] = 1.0f;
    return result;
}

mat4 mat4::rotation_x(float angle_rad) {
    mat4 result = identity();
    float c = std::cos(angle_rad);
    float s = std::sin(angle_rad);
    result.m[1][1] = c;
    result.m[1][2] = s;
    result.m[2][1] = -s;
    result.m[2][2] = c;
    return result;
}

mat4 mat4::rotation_y(float angle_rad) {
    mat4 result = identity();
    float c = std::cos(angle_rad);
    float s = std::sin(angle_rad);
    result.m[0][0] = c;
    result.m[0][2] = -s;
    result.m[2][0] = s;
    result.m[2][2] = c;
    return result;
}

mat4 mat4::rotation_z(float angle_rad) {
    mat4 result = identity();
    float c = std::cos(angle_rad);
    float s = std::sin(angle_rad);
    result.m[0][0] = c;
    result.m[0][1] = s;
    result.m[1][0] = -s;
    result.m[1][1] = c;
    return result;
}

float* mat4::data() {
    return &m[0][0];
}

const float* mat4::data() const {
    return &m[0][0];
}

} // namespace math
} // namespace assimp_lite
