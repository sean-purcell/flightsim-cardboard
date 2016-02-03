//
//  GameViewController.m
//  Flightsim Cardboard
//
//  Created by Sean Purcell on 2016-01-29.
//  Copyright © 2016 Sean Purcell. All rights reserved.
//

#import "GameViewController.h"

#include "CardboardSDK.h"

#import <OpenGLES/ES2/glext.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

void printMatrix(int line, GLKMatrix4 m) {
	NSMutableString *s = [NSMutableString stringWithString:@""];
	for(int i = 0; i < 4; i++) {
		for(int j = 0; j < 4; j++) {
			[s appendString: [NSString stringWithFormat:@"%f ", m.m[i*4+j]]];
		}
	}
	
	NSLog(@"%d: %@", line, s)
}

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

GLfloat gCubeVertexData[216] = 
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    0.5f, -0.5f, -0.5f,        1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,          1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    
    0.5f, 0.5f, -0.5f,         0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 1.0f, 0.0f,
    
    -0.5f, 0.5f, -0.5f,        -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        -1.0f, 0.0f, 0.0f,
    
    -0.5f, -0.5f, -0.5f,       0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         0.0f, -1.0f, 0.0f,
    
    0.5f, 0.5f, 0.5f,          0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, 0.0f, 1.0f,
    
    0.5f, -0.5f, -0.5f,        0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 0.0f, -1.0f
};

@interface GameRenderer : NSObject {
    GLuint _program;
    
    GLKMatrix4 _modelViewMatrix1;
    GLKMatrix3 _normalMatrix1;
	GLKMatrix4 _modelViewMatrix2;
	GLKMatrix3 _normalMatrix2;
	
	GLKMatrix4 _headView;
	
    float _rotation;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
	
	GLint _positionLoc;
	GLint _normalLoc;
	
	GLint _colorLoc;
	
	GLint _modelViewProjectionMatrixLoc;
	GLint _normalMatrixLoc;
}

@end

@implementation GameRenderer

- (instancetype)init
{
	self = [super init];
	if (!self) { return nil; }
	
	return self;
}

- (void)setupRendererWithView:(GLKView *)glView
{
	[EAGLContext setCurrentContext: glView.context];
	
	[self setupPrograms];
	
	[self setupVAOS];
	
	glEnable(GL_DEPTH_TEST);
	
	GLCheckForError();
}

- (BOOL)setupPrograms
{
	NSString *path = nil;
	
	GLuint vertexShader = 0;
	path = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
	if(!GLCompileShaderFromFile(&vertexShader, GL_VERTEX_SHADER, path)) {
		NSLog(@"Failed to compile shader at %@", path);
		return NO;
	}
	
	GLuint fragmentShader = 0;
	path = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
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
	
	glUseProgram(_program);
	
	return YES;
}

- (void)setupVAOS
{
	_positionLoc = glGetAttribLocation(_program, "position");
	_normalLoc = glGetAttribLocation(_program, "normal");
	
	_colorLoc = glGetUniformLocation(_program, "color");
	_modelViewProjectionMatrixLoc = glGetUniformLocation(_program, "modelViewProjectionMatrix");
	_normalMatrixLoc = glGetUniformLocation(_program, "normalMatrix");
	
	glGenVertexArraysOES(1, &_vertexArray);
	glBindVertexArrayOES(_vertexArray);
	
	glGenBuffers(1, &_vertexBuffer);
	glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
	
	glEnableVertexAttribArray(_positionLoc);
	glEnableVertexAttribArray(_normalLoc);
	
	glVertexAttribPointer(_positionLoc, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
	glVertexAttribPointer(_normalLoc, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
	
	GLCheckForError();
}

- (void)shutdownRendererWithView:(GLKView *)glView
{
}

- (void)renderViewDidChangeSize:(CGSize)size
{
}

- (void)prepareNewFrameWithHeadViewMatrix:(GLKMatrix4)headViewMatrix
{
	_headView = headViewMatrix;

	GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
	baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
	
	GLKMatrix4 modelViewMatrix1 = GLKMatrix4MakeTranslation(0.0f, 0.0f, 1.5f);
	modelViewMatrix1 = GLKMatrix4Rotate(modelViewMatrix1, _rotation, 1.0f, 1.0f, 1.0f);
	modelViewMatrix1 = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix1);
	
	GLKMatrix4 modelViewMatrix2 = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.5f);
	modelViewMatrix2 = GLKMatrix4Rotate(modelViewMatrix1, _rotation, 1.0f, 1.0f, 1.0f);
	modelViewMatrix2 = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix1);
	
	_modelViewMatrix1 = modelViewMatrix1;
	_modelViewMatrix2 = modelViewMatrix2;
	
	GLCheckForError();
}

- (void)updateRotation:(float)timeSinceLastUpdate
{
	_rotation += timeSinceLastUpdate * 0.5f;
}

- (void)drawEyeWithEye:(CBDEye *)eye
{
	glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	//DLog(@"%ld %@", eye.type, NSStringFromGLKMatrix4([eye eyeViewMatrix]));

	GLCheckForError();
	
	GLKMatrix4 perspective = [eye perspectiveMatrixWithZNear:0.1f zFar:100.0f];
	
	glUseProgram(_program);
	glBindVertexArrayOES(_vertexArray);
	glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
	
	// Draw each cube
	[self drawCubeWithEye: eye andPerspective: perspective andModel: _modelViewMatrix1];
	[self drawCubeWithEye: eye andPerspective: perspective andModel: _modelViewMatrix2];
	
	glBindVertexArrayOES(0);
	glUseProgram(0);
}

- (void)drawCubeWithEye:(CBDEye *) eye andPerspective:(GLKMatrix4) perp andModel:(GLKMatrix4) model
{
	//GLKMatrix4 view = GLKMatrix4Multiply([eye eyeViewMatrix], model);
	GLKMatrix4 view = model;
	
	GLKMatrix3 normal = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(view), NULL);
	GLKMatrix4 projectView = GLKMatrix4Multiply(perp, view);
	
	glUniformMatrix4fv(_modelViewProjectionMatrixLoc, 1, 0, projectView.m);
	glUniformMatrix3fv(_normalMatrixLoc, 1, 0, normal.m);
	
	DLog(@"%ld %@", eye.type, NSStringFromGLKMatrix4(projectView));
	
	GLKVector4 testP = GLKVector4Make(0.0f, 0.0f, -0.5f, 1.0f);
	DLog(@"%@", NSStringFromGLKVector4(GLKMatrix4MultiplyVector4(projectView, testP)));
	
	glDrawArrays(GL_TRIANGLES, 0, 36);
	
	GLCheckForError();
}

- (void)finishFrameWithViewportRect:(CGRect)viewPort
{
}

@end

@interface GameViewController() <CBDStereoRendererDelegate>

@property (nonatomic) GameRenderer *gameRenderer;

@end

@implementation GameViewController
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
	if (!self) { return nil; }
	
	self.stereoRendererDelegate = self;
	
	return self;
}

- (void)setupRendererWithView:(GLKView *)glView
{
	self.gameRenderer = [GameRenderer new];
	[self.gameRenderer setupRendererWithView: glView];
	
	CGRect eyeFrame = self.view.bounds;
	eyeFrame.size.height = self.view.bounds.size.height;
	eyeFrame.size.width = self.view.bounds.size.width / 2;
	
	eyeFrame.origin.y = eyeFrame.size.height;
}

- (void)shutdownRendererWithView:(GLKView *)glView
{
	[self.gameRenderer shutdownRendererWithView: glView];
}

- (void)renderViewDidChangeSize:(CGSize)size
{
	[self.gameRenderer renderViewDidChangeSize: size];
}

- (void)prepareNewFrameWithHeadViewMatrix:(GLKMatrix4)headViewMatrix
{
	[self.gameRenderer prepareNewFrameWithHeadViewMatrix: headViewMatrix];
	[self.gameRenderer updateRotation: self.timeSinceLastUpdate];
}

- (void)drawEyeWithEye:(CBDEye *)eye
{
	[self.gameRenderer drawEyeWithEye: eye];
}

- (void)finishFrameWithViewportRect:(CGRect)viewPort
{
	[self.gameRenderer finishFrameWithViewportRect: viewPort];
}

@end
