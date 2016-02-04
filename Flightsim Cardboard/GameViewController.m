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

#import "TerrainRenderer.h"

/*
@interface GameRenderer : NSObject

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
	
	_terrainProgram = glCreateProgram();
	glAttachShader(_terrainProgram, vertexShader);
	glAttachShader(_terrainProgram, fragmentShader);
	GLLinkProgram(_terrainProgram);
	glUseProgram(_terrainProgram);
	
	GLCheckForError();
	
	glUseProgram(_terrainProgram);
	
	return YES;
}

- (void)setupVAOS
{
	_positionLoc = glGetAttribLocation(_terrainProgram, "position");
	_normalLoc = glGetAttribLocation(_terrainProgram, "normal");
	
	_colorLoc = glGetUniformLocation(_terrainProgram, "color");
	_modelViewProjectionMatrixLoc = glGetUniformLocation(_terrainProgram, "modelViewProjectionMatrix");
	_normalMatrixLoc = glGetUniformLocation(_terrainProgram, "normalMatrix");
	
	glGenVertexArraysOES(1, &_terrainVertexArray);
	glBindVertexArrayOES(_terrainVertexArray);

	GLCheckForError();
}

- (void)shutdownRendererWithView:(GLKView *)glView
{
}

- (void)renderViewDidChangeSize:(CGSize)size
{
}

- (void)updateWithDt:(float)dt andPosition:(GLKVector3) pos andHeadView:(GLKMatrix4)headView
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
	
	glUseProgram(_terrainProgram);
	glBindVertexArrayOES(_terrainVertexArray);
	glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
	
	// Draw each cube
	[self drawCubeWithEye: eye andPerspective: perspective andModel: _modelViewMatrix1 andColor: GLKVector3Make(0.4f, 0.4f, 1.0f)];
	[self drawCubeWithEye: eye andPerspective: perspective andModel: _modelViewMatrix2 andColor: GLKVector3Make(1.0f, 0.4f, 0.4f)];
	
	glBindVertexArrayOES(0);
	glUseProgram(0);
}

- (void)drawCubeWithEye:(CBDEye *) eye andPerspective:(GLKMatrix4) perp andModel:(GLKMatrix4) model andColor:(GLKVector3) color
{
	GLKMatrix4 view = GLKMatrix4Multiply([eye eyeViewMatrix], model);

#if (TARGET_IPHONE_SIMULATOR)
	// If running on the simulator, don't apply the eye matrix
	view = model;
#endif
	
	GLKMatrix3 normal = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(view), NULL);
	GLKMatrix4 projectView = GLKMatrix4Multiply(perp, view);
	
	glUniformMatrix4fv(_modelViewProjectionMatrixLoc, 1, 0, projectView.m);
	glUniformMatrix3fv(_normalMatrixLoc, 1, 0, normal.m);
	glUniform3f(_colorLoc, color.r, color.g, color.b);
	
	glDrawArrays(GL_TRIANGLES, 0, 36);
	
	GLCheckForError();
}

- (void)finishFrameWithViewportRect:(CGRect)viewPort
{
}

@end
 
 */

@interface GameViewController() <CBDStereoRendererDelegate>

@property (nonatomic) TerrainRenderer *terrainRenderer;

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
	self.terrainRenderer = [[TerrainRenderer alloc] init];

	[self.terrainRenderer setupRendererWithView: glView];
	
	CGRect eyeFrame = self.view.bounds;
	eyeFrame.size.height = self.view.bounds.size.height;
	eyeFrame.size.width = self.view.bounds.size.width / 2;
	
	eyeFrame.origin.y = eyeFrame.size.height;
}

- (void)shutdownRendererWithView:(GLKView *)glView
{
	[self.terrainRenderer shutdownRendererWithView: glView];
}

- (void)renderViewDidChangeSize:(CGSize)size
{
	[self.terrainRenderer renderViewDidChangeSize: size];
}

- (void)prepareNewFrameWithHeadViewMatrix:(GLKMatrix4)headViewMatrix
{
	[self.terrainRenderer updateWithDt: self.timeSinceLastUpdate
						andPosition: GLKVector3Make(0.0f, 2 00.0f, 0.0f)
						andHeadView: headViewMatrix];
}

- (void)drawEyeWithEye:(CBDEye *)eye
{
	[self.terrainRenderer drawEyeWithEye: eye];
}

- (void)finishFrameWithViewportRect:(CGRect)viewPort
{
	[self.terrainRenderer finishFrameWithViewportRect: viewPort];
}

@end
