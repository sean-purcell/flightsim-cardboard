//
//  TerrainRenderer.m
//  Flightsim Cardboard
//
//  Created by Sean Purcell on 2016-02-03.
//  Copyright © 2016 Sean Purcell. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <OpenGLES/ES2/glext.h>

#import "CardboardSDK.h"

#import "Simplex.hpp"
#import "glmheaders.hpp"

#include <utility>
#include <map>

#define CHUNKCOUNT 32 // the number of triangles along a chunk edge
#define CHUNKWIDTH 1024. // how wide the chunk is
#define CHUNKRATIO (CHUNKWIDTH/CHUNKCOUNT)

#define CHUNKSAROUND 10 // radius of loaded chunks shown

const vec3 SKY_COLOR = vec3(135, 206, 235) / 255.f;

int srandBit(int i, int j) {
	srand(i*65537 + j);
	return (rand()>(RAND_MAX)/2);
}

typedef std::pair<int,int> IntPair;

@class ChunkManager;
@class TerrainRenderer;

@interface TerrainChunk : NSObject {
	GLuint _vbo, _ebo;
	
	int _seed;
	
	int _x, _z;
}

- (instancetype)initWithCM:(ChunkManager *)cm x:(int) x z:(int) z;
- (void)drawWithTR: (TerrainRenderer *) tr;

@end

@interface ChunkManager : NSObject {
	std::map<IntPair, TerrainChunk *> _loaded;
	
	float _frequency;
	int _seed;
	int _octaves;
	
	Simplex _noise;
	Simplex _amp;
	Simplex _pers;
}

- (void)updateWithPos:(GLKVector3) pos;
- (void)drawAllChunksWithTR: (TerrainRenderer *) tr;

@end

@interface TerrainRenderer : NSObject {
	GLuint _program;
	
	GLuint _vertexArray;
	
	GLint _projViewLoc;
	
	GLKVector3 _position;
}

@property (nonatomic) ChunkManager *chunkManager;

@property (nonatomic) GLint positionLoc;
@property (nonatomic) GLint colorLoc;

@end

@implementation TerrainRenderer

- (instancetype)init
{
	self = [super init];
	if(!self) { return nil; }
	
	_chunkManager = [[ChunkManager alloc] init];
	
	return self;
}

- (void)setupRendererWithView:(GLKView *)glView
{
	[EAGLContext setCurrentContext: glView.context];
	
	[self setupProgram];
	[self setupVAOS];
	
	_position = GLKVector3Make(0.0, 0.0, 0.0);
	
	glEnable(GL_DEPTH_TEST);
	
	GLCheckForError();
}

- (BOOL)setupProgram
{
	NSString *path = nil;
	
	GLuint vertexShader = 0;
	path = [[NSBundle mainBundle] pathForResource:@"TerrainShader" ofType:@"vsh"];
	if(!GLCompileShaderFromFile(&vertexShader, GL_VERTEX_SHADER, path)) {
		NSLog(@"Failed to compile shader at %@", path);
		return NO;
	}
	
	GLuint fragmentShader = 0;
	path = [[NSBundle mainBundle] pathForResource:@"TerrainShader" ofType:@"fsh"];
	if(!GLCompileShaderFromFile(&fragmentShader, GL_FRAGMENT_SHADER, path)) {
		NSLog(@"Failed to compile shader at %@", path);
		return NO;
	}
	
	_program = glCreateProgram();
	glAttachShader(_program, vertexShader);
	glAttachShader(_program, fragmentShader);
	GLLinkProgram(_program);
	
	glUseProgram(_program);
	
	GLCheckForError();
	
	return YES;
}

- (void)setupVAOS
{
	_positionLoc = glGetAttribLocation(_program, "position");
	_colorLoc = glGetAttribLocation(_program, "color");
	
	_projViewLoc = glGetUniformLocation(_program, "projView");
	
	glGenVertexArraysOES(1, &_vertexArray);
	glBindVertexArrayOES(_vertexArray);
	
	glEnableVertexAttribArray(_positionLoc);
	glEnableVertexAttribArray(_colorLoc);
	
	GLuint horizonLoc = glGetUniformLocation(_program, "HORIZON");
	glUniform1f(horizonLoc, 0.8 * CHUNKSAROUND * CHUNKWIDTH);

	GLuint skyColorLoc = glGetUniformLocation(_program, "SKY_COLOR");
	glUniform3fv(skyColorLoc, 1, value_ptr(SKY_COLOR));
	
	vec3 LIGHT_DIR = normalize(vec3(0, 1, 0.1));
	GLuint lightDirLoc = glGetUniformLocation(_program, "LIGHT_DIR");
	glUniform3fv(lightDirLoc, 1, value_ptr(LIGHT_DIR));
}

- (void)shutdownRendererWithView:(GLKView *)glView
{
}

- (void)renderViewDidChangeSize:(CGSize)size
{
}

- (void)updateWithDt:(float)dt andPosition:(GLKVector3) pos andHeadView:(GLKMatrix4)headView
{
	float s = 500 * dt;
	GLKVector3 forw = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(headView, NULL), GLKVector3Make(0, 0, s));
	NSLog(@"Forward: %@", NSStringFromGLKVector3(forw));
	forw = GLKVector3Make(forw.x, -forw.y, forw.z);
	
	_position = GLKVector3Add(_position, forw);
	if(_position.x != _position.x) {
		_position = GLKVector3Make(0.0, 200.0, 0.0);
	}
	NSLog(@"Position: %@", NSStringFromGLKVector3(_position));
	[_chunkManager updateWithPos: _position];
}

- (void)drawEyeWithEye:(CBDEye *)eye
{
	glClearColor(SKY_COLOR.r, SKY_COLOR.g, SKY_COLOR.b, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glEnable(GL_DEPTH_TEST);
	glDisable(GL_BLEND);
	
	//DLog(@"%ld %@", eye.type, NSStringFromGLKMatrix4([eye eyeViewMatrix]));
	
	GLCheckForError();
	
	GLKMatrix4 perspective = [eye perspectiveMatrixWithZNear:10.0f zFar: 2 * CHUNKSAROUND * CHUNKWIDTH];
	
	GLKMatrix4 view = GLKMatrix4Identity;
	view = GLKMatrix4RotateY(view, M_PI);
	view = GLKMatrix4Translate(view, -_position.x, -_position.y, -_position.z);
	
#if !(TARGET_IPHONE_SIMULATOR)
	view = GLKMatrix4Multiply([eye eyeViewMatrix], view);
#endif
	
	GLKMatrix4 projView = GLKMatrix4Multiply(perspective, view);
	
	glUseProgram(_program);
	glBindVertexArrayOES(_vertexArray);
	
	glUniformMatrix4fv(_projViewLoc, 1, 0, projView.m);
	
	[_chunkManager drawAllChunksWithTR: self];
	
	glBindVertexArrayOES(0);
	glUseProgram(0);
}

- (void)finishFrameWithViewportRect:(CGRect)viewPort
{
}

@end

@implementation ChunkManager

- (instancetype)init
{
	self = [super init];
	if(!self) { return nil; }
	
	[self assignNoiseParams];
	
	return self;
}

- (void)assignNoiseParams
{
	_seed = arc4random() % 65536;
	NSLog(@"seed: %d", _seed);
	_octaves = 10;
	_frequency = 0.064e-2;
	_noise = Simplex(_frequency, 0.5, 25, _octaves, _seed);
	_amp = Simplex(_frequency * 1e-1, 0.3, 1, 3, 2*_seed+1);
	_pers = Simplex(_frequency * 1e-1, 0.3, 1, 3, 3*_seed+7);
}

- (float)getHeightWithX:(float) x Z:(float) z
{
	float ampl = 1.1 + _amp.getValue(x, z);
	ampl = 160 * ampl * ampl;
	float pers = 0.4 + 0.3*_pers.getValue(x, z);
	_noise.set(_frequency, pers, ampl, _octaves, _seed);
	return _noise.getValue(x, z);
}

- (float)getAmpWithX:(float) x Z:(float) z
{
	return _amp.getValue(x, z);
}

- (float)getPersWithX:(float) x Z:(float) z
{
	return _pers.getValue(x, z);
}

- (vec3)getBiomeColorWithPers:(float) pers andAmp:(float)amp
{
	return vec3(0.4, 1.0, 0.4);
}

- (void)updateWithPos:(GLKVector3) pos
{
	float x = pos.x;
	float z = pos.z;
	
	int xchunk = floor(x/CHUNKWIDTH);
	int zchunk = floor(z/CHUNKWIDTH);
	
	for(std::map<IntPair, TerrainChunk *>::iterator it = _loaded.begin();
		it != _loaded.end();) {

		if(abs(xchunk - it->first.first) > CHUNKSAROUND ||
		   abs(zchunk - it->first.second) > CHUNKSAROUND) {
			IntPair tmp = it->first;
			it++;
			[self freeChunk: tmp];
		} else {
			it++;
		}
	}
	
	for(int i = xchunk - CHUNKSAROUND; i <= xchunk + CHUNKSAROUND; i++) {
		for(int j = zchunk - CHUNKSAROUND; j <= zchunk + CHUNKSAROUND; j++) {
			IntPair key = IntPair(i, j);
			[self loadChunk: key];
		}
	}
}

- (void)drawAllChunksWithTR:(TerrainRenderer *) tr
{
	for(std::map<IntPair, TerrainChunk *>::iterator it = _loaded.begin();
		it != _loaded.end(); it++) {
		
		[it->second drawWithTR: tr];
	}
}

- (void)loadChunk:(IntPair) key
{
	if(![self isLoaded: key]) {
		_loaded[key] = [[TerrainChunk alloc] initWithCM: self x: key.first z: key.second];
		NSLog(@"Loading chunk: %d %d", key.first, key.second);
	}
}

- (void)freeChunk:(IntPair) key
{
	if([self isLoaded: key]) {
		_loaded[key] = nil;
		_loaded.erase(key);
	}
}

- (BOOL)isLoaded:(IntPair) key
{
	return _loaded.find(key) != _loaded.end();
}

@end

@implementation TerrainChunk

- (instancetype)initWithCM:(ChunkManager *)cm x:(int) x z:(int) z
{
	self = [super init];
	if(!self) { return nil; }
	
	_x = x;
	_z = z;
	
	glGenBuffers(1, &_vbo);
	glGenBuffers(1, &_ebo);
	glBindBuffer(GL_ARRAY_BUFFER, _vbo);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _ebo);
	
	[self genTerrainWithCM: cm];
	
	GLCheckForError();
	
	return self;
}

- (void)genTerrainWithCM:(ChunkManager *)cm
{
	float *heights = new float[(CHUNKCOUNT + 3) * (CHUNKCOUNT + 3)];
	float *vertices = new float[(3 + 3) * (CHUNKCOUNT + 1) * (CHUNKCOUNT + 1)];
	GLushort *indices = new GLushort[CHUNKCOUNT * CHUNKCOUNT * 3 * 2];
	
	for(int i = -1; i <= CHUNKCOUNT + 1; i++) {
		for(int j = -1; j <= CHUNKCOUNT + 1; j++) {
			float x0 = i * CHUNKRATIO + _x * CHUNKWIDTH;
			float z0 = j * CHUNKRATIO + _z * CHUNKWIDTH;
			heights[(i+1) * (CHUNKCOUNT + 3) + j+1] = [cm getHeightWithX: x0 Z: z0];
		}
	}
	
	int idx = 0;
	vec3 start(_x * CHUNKWIDTH, 0, _z * CHUNKWIDTH);
	for(int i = 0; i <= CHUNKCOUNT; i++) {
		for(int j = 0; j <= CHUNKCOUNT; j++) {
			float x0 = i * CHUNKRATIO;
			float z0 = j * CHUNKRATIO;
			
			float height = heights[(i+1) * (CHUNKCOUNT+3)
								   + (j+1)];
			
			vec3 v(x0, height, z0);
			
			v = v + start;
			
			vertices[idx * 6 + 0] = v.x;
			vertices[idx * 6 + 1] = v.y;
			vertices[idx * 6 + 2] = v.z;
			
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
			
			vec3 vcolor = [cm
			getBiomeColorWithPers: [cm getPersWithX: _x*CHUNKWIDTH+x0 Z: _z*CHUNKWIDTH+z0]
						   andAmp: [cm  getAmpWithX: _x*CHUNKWIDTH+x0 Z: _z*CHUNKWIDTH+z0]];
			
			vertices[idx * 6 + 3] = (float) vcolor.x;
			vertices[idx * 6 + 4] = (float) vcolor.y;
			vertices[idx * 6 + 5] = (float) vcolor.z;
			
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
			if(srandBit(i + _x * CHUNKCOUNT,
						j + _z * CHUNKCOUNT)) {
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
	
	glBufferData(GL_ARRAY_BUFFER, sizeof(float) * (3 + 3) *
				 (CHUNKCOUNT + 1) * (CHUNKCOUNT + 1), vertices, GL_STATIC_DRAW);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLushort) * CHUNKCOUNT
				 * CHUNKCOUNT * 3 * 2, indices, GL_STATIC_DRAW);
	
	delete[] heights;
	delete[] vertices;
	delete[] indices;
}

- (void)drawWithTR:(TerrainRenderer *) tr
{
	glBindBuffer(GL_ARRAY_BUFFER, _vbo);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _ebo);
	
	glVertexAttribPointer(tr.positionLoc, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat),
						  (void*)0);
	glVertexAttribPointer(tr.colorLoc, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat),
						  (void*)(3 * sizeof(GLfloat)));
	
	glDrawElements(GL_TRIANGLES, CHUNKCOUNT * CHUNKCOUNT * 2 * 3,
				   GL_UNSIGNED_SHORT, 0);
}

@end
