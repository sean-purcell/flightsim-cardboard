#ifndef BIOME_PROCESSOR_HPP
#define BIOME_PROCESSOR_HPP

#include "lodepng.h"

#include <vector>

#include "openglheaders.hpp"

extern std::vector<unsigned char> biomeColors;

void loadBiomeImage(std::string filename);

vec3 getBiomeColor(float persistence, float amplitude, std::vector<unsigned char> &image);
vec4 getHudColor();

#endif
