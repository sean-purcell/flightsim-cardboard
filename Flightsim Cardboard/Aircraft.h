//
//  Aircraft.h
//  Flightsim Cardboard
//
//  Created by Sean Purcell on 2016-02-06.
//  Copyright © 2016 Sean Purcell. All rights reserved.
//

#import "glmheaders.hpp"

@interface Aircraft : NSObject
- (void)updateWithDt:(float) dt;

@property vec3 pos;
@property vec3 vel;
@property vec3 omega;
@property quat facing;

@end
