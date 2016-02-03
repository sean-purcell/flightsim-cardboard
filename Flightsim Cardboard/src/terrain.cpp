#include <cstdlib>
#include <cmath>
#include <algorithm>
#include <functional>
#include <iostream>

#include "terrain.hpp"
#include "simplexnoise.hpp"
#include "openglutil.hpp"
#include "biome-processor.hpp"

int srandBit(int i, int j){
	srand(i*65537 + j);
	return (rand()>(RAND_MAX)/2);
}

//implemented based on pseudocode on en.wikipedia.org/wiki/Perlin_noise

Terrain::Terrain(int _seed, int _octaves) : seed(_seed),
	octaves(_octaves),
	frequency(0.064e-2),
	noise(frequency, 0.5, 25, _octaves, seed),
	amp(frequency * 1e-1, 0.3, 1, 3, 2*seed+1),
	pers(frequency * 1e-1, 0.3, 1, 3, 3*seed+7) {
	// frequency, persistence, amplitude, octaves, randomseed
}


float Terrain::getAmplitude(float x, float y){
	return amp.getValue(x,y);
}

float Terrain::getPersistence(float x, float y){
	return pers.getValue(x,y);
}

float Terrain::getHeight(float x, float y){
	float ampl = 1.1 + getAmplitude(x, y);
	ampl = ampl * ampl;
	noise.set(frequency, 0.4+0.3*getPersistence(x, y), 160*ampl, octaves, seed);
	return noise.getValue(x, y);
}

TerrainChunk* Terrain::getChunk(IntPair key){
	return new TerrainChunk(key.first, key.second, *this);
}

float interp(float a, float b, float r) {
	return a * (1-r) + b * r;
}

float TerrainChunk::getHeight(float x, float y) {
	return t.getHeight(x * CHUNKRATIO + this->x * CHUNKWIDTH,
		y * CHUNKRATIO + this->z * CHUNKWIDTH);
}

TerrainChunk::TerrainChunk(int _x, int _z, Terrain &_t) :
	x(_x),
	z(_z),
	t(_t),
	shouldRemove(false),
	next(NULL)
{
	glGenBuffers(1, &vbo);
	glGenBuffers(1, &ebo);
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);

	initVertices();
}

TerrainChunk::~TerrainChunk() {
	glDeleteBuffers(1, &vbo);
	glDeleteBuffers(1, &ebo);
}

float min(float a, float b) {
	return a < b ? a : b;
}

void TerrainChunk::initVertices() {
	float *heights = new float[(CHUNKCOUNT + 3) *
		(CHUNKCOUNT + 3)];
	float *vertices = new float[(3 + 3 + 3) *
		(CHUNKCOUNT + 1) * (CHUNKCOUNT + 1)];
	GLushort *indices = new GLushort[CHUNKCOUNT *
		CHUNKCOUNT * 3 * 2];

	for(int i = -1; i <= CHUNKCOUNT + 1; i++) {
		for(int j = -1; j <= CHUNKCOUNT + 1; j++) {
			float x0 = i * CHUNKRATIO;
			float z0 = j * CHUNKRATIO;
			heights[(i+1) * (CHUNKCOUNT + 3) + j+1] = t.getHeight(
				x0 + this->x * CHUNKWIDTH,
				z0 + this->z * CHUNKWIDTH);
		}
	}

	int idx = 0;
	vec3 start = vec3(x * CHUNKWIDTH, 0, z * CHUNKWIDTH);
	for(int i = 0; i <= CHUNKCOUNT; i++) {
		for(int j = 0; j <= CHUNKCOUNT; j++) {
			float x0 = i * CHUNKRATIO;
			float z0 = j * CHUNKRATIO;

			float height = heights[(i+1) * (CHUNKCOUNT+3)
				+ (j+1)];

			vec3 v = vec3(x0, height, z0);

			v = v + start;

			vertices[idx * 9 + 0] = v.x;
			vertices[idx * 9 + 1] = v.y;
			vertices[idx * 9 + 2] = v.z;

			vec3 norm(0,0,0);
			int dx[] = {1,-1,0,0};
			int dz[] = {0,0,-1,1};

			for(int k = 0; k < 4; k++) {
				vec3 edge(dx[k],
					heights[(i + dx[k] + 1) * (CHUNKCOUNT+3)
					+ (j + dz[k] + 1)],
					dz[k]);

				vec3 up(0, 1, 0);

				norm += cross(cross(edge, up), edge);
			}

			norm = normalize(norm);

			vertices[idx * 9 + 3] = norm.x;
			vertices[idx * 9 + 4] = norm.y;
			vertices[idx * 9 + 5] = norm.z;

			vec3 vcolor = getBiomeColor(t.getPersistence(x*CHUNKWIDTH+x0, z*CHUNKWIDTH+z0), t.getAmplitude(x*CHUNKWIDTH+x0, z*CHUNKWIDTH+z0), biomeColors);

			vertices[idx * 9 + 6] = (float) vcolor.x;
			vertices[idx * 9 + 7] = (float) vcolor.y;
			vertices[idx * 9 + 8] = (float) vcolor.z;

			idx++;
		}
	}

	idx = 0;
	for(int i = 0; i < CHUNKCOUNT; i++) {
		for(int j = 0; j < CHUNKCOUNT; j++) {
			int
				c1 = (i + 0) * (CHUNKCOUNT + 1) + (j + 0),
				c2 = (i + 1) * (CHUNKCOUNT + 1) + (j + 0),
				c3 = (i + 0) * (CHUNKCOUNT + 1) + (j + 1),
				c4 = (i + 1) * (CHUNKCOUNT + 1) + (j + 1);
			if(srandBit(i + this->x * CHUNKCOUNT,
				j + this->z * CHUNKCOUNT)) {
				indices[idx++] = c1;
				indices[idx++] = c2;
				indices[idx++] = c3;
				
				indices[idx++] = c4;
				indices[idx++] = c2;
				indices[idx++] = c3;
			} else {
				indices[idx++] = c1;
				indices[idx++] = c2;
				indices[idx++] = c4;

				indices[idx++] = c1;
				indices[idx++] = c3;
				indices[idx++] = c4;
			}
		}
	}

	glBufferData(GL_ARRAY_BUFFER, sizeof(float) * (3 + 3 + 3) *
		(CHUNKCOUNT + 1) * (CHUNKCOUNT + 1), vertices, GL_STATIC_DRAW);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLushort) * CHUNKCOUNT
		* CHUNKCOUNT * 3 * 2, indices, GL_STATIC_DRAW);

	free(heights);
	free(vertices);
	free(indices);
}

void TerrainChunk::draw() {
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
	updateTerVertexAttribs();
	glDrawElements(GL_TRIANGLES, CHUNKCOUNT * CHUNKCOUNT * 2 * 3,
		GL_UNSIGNED_SHORT, 0);
}

ChunkManager::ChunkManager(Terrain _terrain):
	terrain(_terrain)
	{}

TerrainChunk* ChunkManager::getNewChunks(float x, float z, int chunksAround){
	//x,z are the coordinates of the player
	//distanceToLoad is the range around the player that you want to load chunks in
	int xchunk = floor(x/CHUNKWIDTH);
	int zchunk = floor(z/CHUNKWIDTH);
	
	IntPair key;

	TerrainChunk *head = NULL;
	TerrainChunk **iter = &head;
	
	
	//remove any unneeded chunks
	ChunkMap::iterator tmp;
	for(ChunkMap::iterator iterator = loaded.begin(); iterator != loaded.end(); ) {
		if (abs(xchunk - iterator->first.first)>chunksAround || abs(zchunk - iterator->first.second)>chunksAround){ //if should be removed
			IntPair tmp = iterator->first;
			iterator++;
			freeChunk(tmp);
		} else {
			iterator++;
		}
	}
	
	//add any chunks that aren't in
	
	int len = 0;
	for (int i=xchunk; i>=xchunk-chunksAround; i = (i >= xchunk ? xchunk + (xchunk-i)-1 : xchunk + xchunk-i)){
		for (int j=zchunk-chunksAround; j<=zchunk+chunksAround; j++){
			key = IntPair(i,j);
			if (!isLoaded(key)){
				loadChunk(key);
				*iter = loaded[key];
				iter = &(*iter)->next;
				len++;
				if(len == 10) return head;
			}
		}
	}
	
	return head;
}

void ChunkManager::loadChunk(IntPair key){
	if (!isLoaded(key)){
		loaded[key] = terrain.getChunk(key);
		loadedChunks++;
	}
}

void ChunkManager::freeChunk(IntPair key){
	if (isLoaded(key)){
		loaded[key]->shouldRemove = true;
		loaded.erase(key);
		loadedChunks--;
	}
}

int ChunkManager::isLoaded(IntPair key){
	return loaded.find(key)!=loaded.end();
}
