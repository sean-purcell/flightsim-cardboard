#include "openglheaders.hpp"

#include <cstdlib>
#include <ctime>
#include <chrono>
#include <cmath>
#include <iostream>
#include <vector>
#include <iomanip>

#include "openglutil.hpp"
#include "terrain.hpp"
#include "aircraft.hpp"
#include "biome-processor.hpp"
#include "hudrender.hpp"

GLint uniTrans;
GLint uniView;
GLuint vao;

vec3 camerapos(0, 0, 3);
quat camerarotation(1,0,0,0);

float left = 0, right = 0, up = 0, down = 0;
int mx, my;

Terrain terrain(0, 0);
ChunkManager chunkmanager(terrain);
TerrainChunk *chunks;

const int chunksAround = 20;

const vec3 GLOBAL_LIGHT_DIRECTION = normalize(vec3(0, 1, 0.1));
vec3 SKY_COLOR = vec3(135, 206, 235) / 255.f;

// min_alt = (scaling factor for amplitude) * (maximum value of amplitude noise) *
//   (sum of geometric series for maximum value of persistence)
const float MIN_ALT = -160 * 2.1 * 1 / (1 - 0.7);
const float HORIZON_DIST = chunksAround * 10 * CHUNKWIDTH;

Aircraft aircraft;

Joystick *ctrl;
bool joystick = false;

const char *biomeFile = "resources/biome-earth.png";

void drawTerrain() {
	terrainMode(true);
	TerrainChunk *iter = chunks;
	while(iter) {
		iter->draw();
		iter = iter->next;
	}
	terrainMode(false);
}

void updateTerrain() {
	TerrainChunk *nchunks = chunkmanager.getNewChunks(camerapos.x, camerapos.z, chunksAround);
	if(!chunks) {
		chunks = nchunks;
	} else {
		TerrainChunk *iter = chunks;
		while(iter->next) iter = iter->next;
		iter->next = nchunks;
	}

	int len = 0;
	TerrainChunk **cur = &chunks;
	while(*cur) {
		if((*cur)->shouldRemove) {
			TerrainChunk *next = (*cur)->next;
			delete *cur;
			*cur = next;
		} else {
			cur = &(*cur)->next;
			len++;
		}
	}
}

void initTerrain() {
	loadBiomeImage(biomeFile);
	SKY_COLOR = vec3(biomeColors[200 * 200 * 4 + 0],
		biomeColors[200 * 200 * 4 + 1],
		biomeColors[200 * 200 * 4 + 2]) / 255.f;

	std::srand(time(NULL));

	int seed = std::rand() % 65536;
	std::cout << "seed: " << seed << std::endl;
	terrain = Terrain(seed, 10);
	chunkmanager = ChunkManager(terrain);

	chunks = NULL;
	updateTerrain();
}

void init() // Called before main loop to set up the program
{
	glEnable(GL_MULTISAMPLE);

// Create Vertex Array Object
	glGenVertexArrays(1, &vao);
	glBindVertexArray(vao);

	GLuint shaderProgram = initShaders();
	initProjmatrix();
	initVertexAttribs();

	initTerrain();

	uniView = glGetUniformLocation(shaderProgram, "view");

	GLint light = glGetUniformLocation(shaderProgram, "LIGHT_DIR");
	glUniform3fv(light, 1, value_ptr(GLOBAL_LIGHT_DIRECTION));
	GLint sky = glGetUniformLocation(shaderProgram, "FOG_COLOR");
	glUniform3fv(sky, 1, value_ptr(SKY_COLOR));

	GLint horizon = glGetUniformLocation(shaderProgram, "horizon");
	GLint horizoncoeff = glGetUniformLocation(shaderProgram, "horizoncoeff");
	float horizonval = 0.8 * chunksAround * CHUNKWIDTH;
	glUniform1f(horizon, horizonval);
	glUniform1f(horizoncoeff, pow(horizonval, -2));

	initHud();

	aircraft = Aircraft();
	prevtime = std::chrono::high_resolution_clock::now();

	std::cout << "init done\n";
}

float ang = 0.f;

void tick() {
	using namespace std::chrono;
	ang += 0.05f;
	if(ang > 2 * M_PI) ang -= 2 * M_PI;

	if(joystick) {
		ctrl->update(10); //if (ctrl->update(10))
        //    std::cout << ">>> ";
        //else
        //    std::cout << "||| ";
		float pitch = ctrl->pitch;
		float roll = ctrl->roll;

		if(pitch != 0.0) {
			down = pitch / M_PI * 4;
			up = 0;
		}
		if(roll != 0.0) {
			left = -roll;
			right = 0;
		}
		aircraft.thrust = Aircraft::MAX_THRUST * (4098 - ctrl->throttle) / 4095;
		//std::cout << getShort(ctrl->port->data, 0) << " " << getShort(ctrl->port->data, 2) << " " << getShort(ctrl->port->data, 4) << "\n";
		//std::cout << pitch << " " << roll << std::endl;
	}

	auto time = high_resolution_clock::now();
	float dt = duration_cast<duration<float> >(time - prevtime).count();
	aircraft.update(dt);
	prevtime = time;

	/*
	camerapos = camerapos + (vec3(0,0, -50. * (float) up) * camerarotation);
	camerapos = camerapos + (vec3(0,0, 50. * (float) down) * camerarotation);
	camerapos = camerapos + (vec3(50. * (float) right, 0, 0) * camerarotation);
	camerapos = camerapos + (vec3(-50. * (float) left, 0, 0) * camerarotation);
	*/

	camerapos = aircraft.pos;
	camerarotation = inverse(aircraft.facing);

	updateTerrain();
}

// Called at the start of the program, after a glutPostRedisplay() and during idle
// to display a frame
void display()
{

	tick();

	glBindVertexArray(vao);

	glClearColor(SKY_COLOR.r, SKY_COLOR.g, SKY_COLOR.b, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	mat4 view(1.f);
	view = translate(view, -camerapos);
	view = mat4_cast(camerarotation) * view;
	view = mat4_cast(angleAxis((float)M_PI, vec3(0,1,0))) * view;

	glUniformMatrix4fv(uniView, 1, GL_FALSE, value_ptr(view));

	drawTerrain();
	drawHud(aircraft.pos, aircraft.facing, aircraft.velocity);

	glutSwapBuffers();
}

void idle() {
	glutPostRedisplay();
}

void keyboardDownFunc(unsigned char c, int x, int y) {
	std::cout << "down:" << c << std::endl;

	switch(c | 0x20) {
	case 'a': left = true; break;
	case 'w': up = true; break;
	case 's': down = true; break;
	case 'd': right = true; break;
	}
}

void keyboardUpFunc(unsigned char c, int x, int y) {
	std::cout << "up  :" << c << std::endl;

	switch(c | 0x20) {
	case 'a': left = false; break;
	case 'w': up = false; break;
	case 's': down = false; break;
	case 'd': right = false; break;
	}
}

void mouseMoveFunc(int x, int y) {
	return;
	int dx = x - mx;
	int dy = y - my;

	quat rot = normalize(quat(1, 0.003*dy, 0.003*dx, 0));
	camerarotation = rot * camerarotation;

	mx = x;
	my = y;
}

void initJoystick(int argc, char **argv) {
	int i;
	for(i = 0; i < argc; i++) {
		if(strcmp(argv[i], "-j") == 0) {
			break;
		}
	}
	if(i == argc) return;
	std::cout << "joystick port (hit enter to use keyboard controls): " << std::flush;
	std::string port;
	std::getline(std::cin, port);
	ctrl = new Joystick(port);
	if (ctrl->port->get_status() != Serial::IDLE) return;
	ctrl->flush();
	joystick = true;
}
