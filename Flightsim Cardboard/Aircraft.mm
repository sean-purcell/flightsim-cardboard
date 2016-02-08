//
//  Aircraft.m
//  Flightsim Cardboard
//
//  Created by Sean Purcell on 2016-02-05.
//  Copyright © 2016 Sean Purcell. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "glmheaders.hpp"

#import "Aircraft.h"

@interface Aircraft ()

- (void) applyForcesWithDt:(float) dt;

- (vec3) fGravity;
- (vec3) fWing;
- (vec3) fThrust;
- (vec3) fDrag;

@end
