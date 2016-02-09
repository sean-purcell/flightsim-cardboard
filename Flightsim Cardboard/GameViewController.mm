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

#import "Aircraft.h"
#import "TerrainRenderer.h"
#import "HudRenderer.h"

@interface GameViewController() <CBDStereoRendererDelegate>

@property (nonatomic) Aircraft *aircraft;
@property (nonatomic) TerrainRenderer *terrainRenderer;
@property (nonatomic) HudRenderer *hudRenderer;

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
	self.aircraft = [[Aircraft alloc] init];
	
	self.terrainRenderer = [[TerrainRenderer alloc] init];
	self.hudRenderer = [[HudRenderer alloc] init];

	[self.terrainRenderer setupRendererWithView: glView];
	[self.hudRenderer setupRendererWithView: glView];
	
	[self.hudRenderer setHudColor: [self.terrainRenderer getHudColor]];
	
	CGRect eyeFrame = self.view.bounds;
	eyeFrame.size.height = self.view.bounds.size.height;
	eyeFrame.size.width = self.view.bounds.size.width / 2;
	
	eyeFrame.origin.y = eyeFrame.size.height;
}

- (void)shutdownRendererWithView:(GLKView *)glView
{
	[self.terrainRenderer shutdownRendererWithView: glView];
	[self.hudRenderer shutdownRendererWithView: glView];
}

- (void)renderViewDidChangeSize:(CGSize)size
{
	[self.terrainRenderer renderViewDidChangeSize: size];
	[self.hudRenderer renderViewDidChangeSize: size];
}

- (void)prepareNewFrameWithHeadViewMatrix:(GLKMatrix4)headViewMatrix
{
	mat4 headView = make_mat4(headViewMatrix.m);
	
	[self.aircraft updateWithDt: self.timeSinceLastUpdate andHeadView: headView];
	
	[self.terrainRenderer updateWithDt: self.timeSinceLastUpdate
						andPosition: self.aircraft.pos
						andHeadView: headView];
	[self.hudRenderer updateWithPos: self.aircraft.pos
						  andFacing: self.aircraft.facing
							 andVel: self.aircraft.vel
						andHeadView: headViewMatrix];
}

- (void)drawEyeWithEye:(CBDEye *)eye
{
	[self.terrainRenderer drawEyeWithEye: eye];
	[self.hudRenderer drawEyeWithEye: eye];
}

- (void)finishFrameWithViewportRect:(CGRect)viewPort
{
	[self.terrainRenderer finishFrameWithViewportRect: viewPort];
	[self.hudRenderer finishFrameWithViewportRect: viewPort];
}

@end
