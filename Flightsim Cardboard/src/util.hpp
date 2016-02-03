#pragma once

#include <iostream>

#include "glmheaders.hpp"

std::ostream & operator<<(std::ostream &out, vec3 const &v);
std::ostream & operator<<(std::ostream &out, quat const &v);

