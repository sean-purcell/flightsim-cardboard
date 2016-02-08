#include <cassert>
#include <cmath>
#include <sstream>
#include <iomanip>
#include "rotation.hpp"
#include "glmheaders.hpp"

Euler::Euler(){}

/** With ZYX convention:
 *      xE points north
 *      yE points east
 *      zE points down
 *  All parameters are in radians.
 */
Euler::Euler(float bank, float elevation, float heading)
{
    roll = bank;
    pitch = elevation;
    yaw = heading;
}

/** Returns an Tait-Bryan z-y-x angle representation of the given rotation quaternion.
 * Maths: https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
 */
Euler Euler::fromRotation(quat facing)
{
    /* Sim coordinate system:
     * z points straight ahead.
     * y points straight up.
     * x points out left wing.
     */

    float q0 = facing.w;
    float q1 = facing.z;
    float q2 = -facing.x;
    float q3 = -facing.y;

    float a = atan2(2*(q0*q1 + q2*q3), 1 - 2*(q1*q1 + q2*q2));
    float b = asin(2*(q0*q2 - q3*q1));
    float c = atan2(2*(q0*q3 + q1*q2), 1 - 2*(q2*q2 + q3*q3));

    // Or: vec3 angles = eulerAngles(r); // pitch as x, yaw as y, roll as z

    return Euler(a, b, c);
}

/** Return the quaternion representation of these Tait-Bryan z-y-x angles.
 * Maths: https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
 */
quat Euler::toQuaternion()
{
    quat labyaw = quat(cos(yaw/2), 0, 0, sin(yaw/2));
    quat labpitch = quat(cos(pitch/2), 0, sin(pitch/2), 0);
    quat labroll = quat(cos(roll/2), sin(roll/2), 0, 0);

    return labyaw * labpitch * labroll;
}

/** Returns a roll angle in the range (-180, 180] degrees.
 */
float Euler::rolld()
{
    return degrees(roll);
}

/** Returns a pitch angle in the range [-90, 90] degrees.
 */
float Euler::pitchd()
{
    return degrees(pitch);
}

/** Returns a yaw angle in the range [0, 360) degrees.
 */
float Euler::yawd()
{
    float h = degrees(yaw);
    if (h < 0) h += 360; // heading is positive
    return h;
}

std::string Euler::toString()
{
	std::ostringstream os;
	os << std::setprecision(3) << std::fixed;
	os << "Pitch: " << pitchd() << " Roll: " << rolld() << " Yaw: " << yawd();
	return os.str();
}

float radians(float degrees)
{
    return degrees / 180 * PI;
}

float degrees(float radians)
{
    return radians / PI * 180;
}
