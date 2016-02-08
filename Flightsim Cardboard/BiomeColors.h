//
//  BiomeColors.h
//  Flightsim Cardboard
//
//  Created by Sean Purcell on 2016-02-04.
//  Copyright © 2016 Sean Purcell. All rights reserved.
//

#import "glmheaders.hpp"

@interface BiomeColors : NSObject

- (instancetype)initWithPath:(NSString *) path;
- (vec3)getBiomeColorWithPers:(float) pers andAmp:(float) amp;
- (vec4)getHudColor;

@end
