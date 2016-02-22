//
//  TerrainRenderer.h
//  Flightsim Cardboard
//
//  Created by Sean Purcell on 2016-02-03.
//  Copyright © 2016 Sean Purcell. All rights reserved.
//

#import "glmheaders.hpp"

#import "Aircraft.h"

@interface TerrainRenderer : NSObject
- (void)setupRendererWithView:(GLKView *)glView;
- (void)shutdownRendererWithView:(GLKView *)glView;
- (void)renderViewDidChangeSize:(CGSize)size;
- (void)updateWithDt:(float)dt andAircraft:(Aircraft *) ac andHeadView:(mat4)headView;
- (void)drawEyeWithEye:(CBDEye *)eye;
- (void)finishFrameWithViewportRect:(CGRect)viewPort;
- (vec4)getHudColor;
@end
