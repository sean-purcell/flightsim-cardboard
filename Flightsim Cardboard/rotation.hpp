#ifndef ROTATION_HPP
#define ROTATION_HPP

#include <cmath>
#include <string>
#include "glmheaders.hpp"

const float PI = acos(-1);

/** These angles are with ZYX convention.
 */
class Euler
{
    public:
        float roll, pitch, yaw; // Extrinsically rotate in sequence roll, pitch, yaw
                                // or intrinsically rotate in sequence yaw, pitch, roll
        Euler();
        Euler(float bank, float elevation, float heading);
        static Euler fromRotation(quat facing);
        static Euler fromRotation(mat3 facing);

        float yawd();
        float pitchd();
        float rolld();

        quat toQuaternion();
        std::string toString();
};

float radians(float degrees);
float degrees(float radians);

#endif
