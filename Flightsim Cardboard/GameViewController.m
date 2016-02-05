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
						andPosition: GLKVector3Make(0.0f, 500.0f, 0.0f)
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
