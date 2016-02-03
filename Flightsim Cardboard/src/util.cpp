#include "util.hpp"

std::ostream & operator<<(std::ostream &out, vec3 const &v) {
	return out << "(" << v.x << "," << v.y << "," << v.z << ")";
}

std::ostream & operator<<(std::ostream &out, quat const &v) {
	return out << "(" << v.w << "," << v.x << "," << v.y << "," << v.z << ")";
}

