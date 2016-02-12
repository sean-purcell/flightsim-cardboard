//
//  HudRender.h
//  Flightsim Cardboard
//
//  Created by Sean Purcell on 2016-02-07.
//  Copyright © 2016 Sean Purcell. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <OpenGLES/ES2/glext.h>

#import "glmheaders.hpp"

@interface HudRenderer : NSObject

- (void)setupRendererWithView:(GLKView *)glView;
- (void)shutdownRendererWithView:(GLKView *)glView;
- (void)renderViewDidChangeSize:(CGSize)size;
- (void)updateWithPos:(vec3) pos andFacing:(mat3)facing andVel:(vec3) vel andHeadView:(GLKMatrix4)headView;
- (void)drawEyeWithEye:(CBDEye *)eye;
- (void)finishFrameWithViewportRect:(CGRect)viewPort;
- (void)setHudColor:(vec4) hudColor;

@end
