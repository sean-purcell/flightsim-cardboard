#include <iostream>
#include "biome-processor.hpp"
#include "openglutil.hpp"

std::vector<unsigned char> biomeColors;

void loadBiomeImage(const std::string filename){
	//reads biome image into img

	std::vector<unsigned char> image;
	unsigned width, height;
	unsigned error = lodepng::decode(image, width, height, filename);
	if(error) std::cout << "decoder error " << error << ": " << lodepng_error_text(error) << std::endl;

	biomeColors = image;
}

vec3 getBiomeColor(float persistence, float amplitude, std::vector<unsigned char> &image){
	//assuming amplitude, persistence are both in [0,1]
	int pers = max(0, min((int) (persistence*100 + 100), 199));
	int amp = max(0, min((int) (amplitude*100 + 100), 199));
	vec3 col = vec3(image[(pers*200 + amp) * 4 + 0], image[(pers*200 + amp) * 4 + 1], image[(pers*200 + amp) * 4 + 2]) / 255.f;//rgb? hopefully
	return col;
}

vec4 getHudColor() {
	int ind = 200 * 200 * 4 + 4;
	std::vector<unsigned char> &image = biomeColors;
	return vec4(image[ind + 0], image[ind + 1], image[ind + 2], image[ind + 3]) / 255.f;
}

