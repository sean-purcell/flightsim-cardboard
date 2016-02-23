//
//  Aircraft.h
//  Flightsim Cardboard
//
//  Created by Sean Purcell on 2016-02-06.
//  Copyright © 2016 Sean Purcell. All rights reserved.
//

#import "glmheaders.hpp"

@interface Aircraft : NSObject
- (void)updateWithDt:(float) dt andHeadView:(mat4) headView;

@property vec3 pos;
@property vec3 vel;
@property vec3 omega;
@property quat facing;

@property float pitchControl;
@property float rollControl;

@end
