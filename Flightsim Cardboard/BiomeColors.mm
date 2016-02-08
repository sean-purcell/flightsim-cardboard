//
//  BiomeColors.m
//  Flightsim Cardboard
//
//  Created by Sean Purcell on 2016-02-04.
//  Copyright © 2016 Sean Purcell. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "glmheaders.hpp"

#import <vector>
#import <string>

#import "lodepng.h"

@interface BiomeColors : NSObject {
	std::vector<unsigned char> _biomeColors;
}
@end

@implementation BiomeColors : NSObject

- (instancetype)initWithPath:(NSString *) path
{
	self = [super init];
	if(!self) { return nil; }
	
	unsigned width, height;
	unsigned error = lodepng::decode(_biomeColors, width, height, [path UTF8String]);
	if(error) NSLog(@"Failed to load biome colors: %@", path);
	
	return self;
}

- (vec3)getBiomeColorWithPers:(float) pers andAmp:(float) amp
{
	std::vector<unsigned char> &image = _biomeColors;
	int persI = max(0, min((int) (pers * 100 + 100), 199));
	int ampI = max(0, min((int) (amp * 100 + 100), 199));
	int ind = (persI*200+ampI)*4;
	return vec3(image[ind+0], image[ind+1], image[ind+2]) / 255.f;
}

- (vec4)getHudColor
{
	int ind = 200 * 200 * 4 + 4;
	std::vector<unsigned char> &image = _biomeColors;
	
	return vec4(image[ind + 0], image[ind + 1], image[ind + 2], image[ind + 3]) / 255.f;
}

@end
