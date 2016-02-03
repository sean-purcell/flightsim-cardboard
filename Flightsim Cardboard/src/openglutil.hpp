#include "openglheaders.hpp"

extern int w, h;

void reshape(int w, int h);
void initializeGLWindow(int argc, char **argv, int w, int h);
GLuint initShaders();
void initProjmatrix();
void initVertexAttribs();
void updateTerVertexAttribs();
void updateHudVertexAttribs();
void selectMode(int mode);
void terrainMode(bool on);
void hudMode(bool on);
void initHudUniforms(vec4 color);

