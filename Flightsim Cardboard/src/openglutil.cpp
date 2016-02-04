#include <cstdio>
#include <iostream>
#include <vector>

#include "openglheaders.hpp"
#include "openglshaders.hpp"
#include "openglutil.hpp"

static GLuint shader;
static GLint projloc;
static GLint posloc, normloc, colloc;
static GLint hudposloc, texcoordloc;
static GLint modeloc;
static mat4 proj;

int w, h;

void reshape(int _w, int _h) {
	w = _w; h = _h;
	glViewport(0, 0, w, h);
	initProjmatrix();
}

void initializeGLWindow(int argc, char **argv, int _w, int _h) {
	glutInit(&argc, argv); // Initializes glut

	// Sets up a double buffer with RGBA components and a depth component
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_DEPTH | GLUT_RGBA | GLUT_MULTISAMPLE
#ifdef __APPLE__
	 | GLUT_3_2_CORE_PROFILE
#endif
	);

	glutInitWindowSize(w = _w, h = _h);

	// Sets the window position to the upper left
	glutInitWindowPosition(0, 0);

	// Creates a window using internal glut functionality
	glutCreateWindow("Flightsim");

#ifdef __linux__
	glewExperimental = GL_TRUE;
	glewInit();
#endif

#ifdef __MINGW32__
	glewExperimental = GL_TRUE;
	glewInit();
#endif

	std::printf("%s\n%s\n",
		glGetString(GL_RENDERER),  // e.g. Intel HD Graphics 3000 OpenGL Engine
		glGetString(GL_VERSION)    // e.g. 3.2 INTEL-8.0.61
		);

	// passes reshape and display functions to the OpenGL machine for callback
	glutReshapeFunc(reshape);

	glutIgnoreKeyRepeat(1);
	glutSetCursor(GLUT_CURSOR_NONE);
}

GLuint initShaders() {
	// Create and compile the vertex shader
	GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
	glShaderSource(vertexShader, 1, &vertexSource, NULL);
	glCompileShader(vertexShader);

	GLint success = 0;
	glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
	if(success != GL_TRUE) {
		GLint logSize = 0;
		glGetShaderiv(vertexShader, GL_INFO_LOG_LENGTH, &logSize);
		// The maxLength includes the NULL character
		std::vector<GLchar> errorLog(logSize);
		glGetShaderInfoLog(vertexShader, logSize, &logSize, &errorLog[0]);
		std::cout << "VShader did not compile:\n";
		std::cout << &errorLog[0] << std::endl;
		exit(1);
	}

	// Create and compile the fragment shader
	GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
	glShaderSource(fragmentShader, 1, &fragmentSource, NULL);
	glCompileShader(fragmentShader);
	success = 0;
	glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);
	if(success != GL_TRUE) {
		GLint logSize = 0;
		glGetShaderiv(fragmentShader, GL_INFO_LOG_LENGTH, &logSize);
		// The maxLength includes the NULL character
		std::vector<GLchar> errorLog(logSize);
		glGetShaderInfoLog(fragmentShader, logSize, &logSize, &errorLog[0]);
		std::cout << "FShader did not compile:\n";
		std::cout << &errorLog[0] << std::endl;
		exit(1);
	}

	// Link the vertex and fragment shader into a shader program
	GLuint shaderProgram = glCreateProgram();
	glAttachShader(shaderProgram, vertexShader);
	glAttachShader(shaderProgram, fragmentShader);
	glBindFragDataLocation(shaderProgram, 0, "outColor");
	glLinkProgram(shaderProgram);
	glUseProgram(shaderProgram);

	projloc = glGetUniformLocation(shaderProgram, "proj");
	modeloc = glGetUniformLocation(shaderProgram, "mode");

	return shader = shaderProgram;
}

void initProjmatrix() {
	proj = infinitePerspective(45.f, w / (float)h, .1f);

	glUniformMatrix4fv(projloc, 1, GL_FALSE, value_ptr(proj));
}

void initHudUniforms(vec4 color) {
	glUniform1i(glGetUniformLocation(shader, "tex"), 0);
	glUniform4fv(glGetUniformLocation(shader, "hudColor"), 1,
		value_ptr(color));

	mat4 trans(1.f);
	trans[2][2] = -1;

	glUniformMatrix4fv(glGetUniformLocation(shader, "hudTrans"),
		1, GL_FALSE, value_ptr(trans));
}

void selectMode(int mode) {
	glUniform1i(modeloc, mode);
}

void terrainMode(bool on) {
	selectMode(0);

	if(on) {
		glEnable(GL_DEPTH_TEST);
		glEnableVertexAttribArray(posloc);
		glEnableVertexAttribArray(normloc);
		glEnableVertexAttribArray(colloc);
	} else {
		glDisable(GL_DEPTH_TEST);
		glDisableVertexAttribArray(posloc);
		glDisableVertexAttribArray(normloc);
		glDisableVertexAttribArray(colloc);
	}
}

void hudMode(bool on) {
	selectMode(1);

	if(on) {
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glEnableVertexAttribArray(hudposloc);
		glEnableVertexAttribArray(texcoordloc);
	} else {
		glDisable(GL_BLEND);
		glDisableVertexAttribArray(hudposloc);
		glDisableVertexAttribArray(texcoordloc);
	}
}

void initVertexAttribs() {
	posloc = glGetAttribLocation(shader, "position");
	normloc = glGetAttribLocation(shader, "normal");
	colloc = glGetAttribLocation(shader, "color");

	hudposloc = glGetAttribLocation(shader, "hudPosition");
	texcoordloc = glGetAttribLocation(shader, "texcoord");
}

void updateTerVertexAttribs() {
	glVertexAttribPointer(posloc, 3, GL_FLOAT, GL_FALSE, 9 * sizeof(GLfloat),
		(void*)0);
	glVertexAttribPointer(normloc, 3, GL_FLOAT, GL_FALSE, 9 * sizeof(GLfloat),
		(void*)(3 * sizeof(GLfloat)));
	glVertexAttribPointer(colloc, 3, GL_FLOAT, GL_FALSE, 9 * sizeof(GLfloat),
		(void*)(6 * sizeof(GLfloat)));
}

void updateHudVertexAttribs() {
	glVertexAttribPointer(hudposloc, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat),
		(void*)0);
	glVertexAttribPointer(texcoordloc, 2, GL_FLOAT, GL_FALSE, 5*sizeof(GLfloat),
		(void*)(3*sizeof(GLfloat)));
}

