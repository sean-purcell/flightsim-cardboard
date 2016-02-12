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

- (void)applyForcesWithDt:(float) dt;

- (vec3)fGravity;
- (vec3)fWing;
- (vec3)fThrust;
- (vec3)fDrag;

@end

@implementation Aircraft {
	float _g;
	float _mass;
	float _thrust;
	float _aoi;
	float _maxaileron;
	float _minaileron;
	float _maxelevator;
	float _minelevator;
	float _wingarea;
	float _pitchmoi;
	float _rollmoi;
	float _yawmoi;
	float _aileronarea;
	float _aileronradius;
	float _elevatorarea;
	float _elevatorradius;
	float _rudderarea;
	float _rudderradius;
	float _rho;
	float _liftcoeff;
	float _dragcoeff;
	float _rudderdampcoeff;
	float _rolldampcoeff;
}

- (instancetype)init
{
	self = [super init];
	if(!self) return nil;
	
	[self setParams];
	
	_pos = vec3(0, 1000.f, 1);
	_facing = mat3(1.f);
	_vel = vec3(0, 0, 500);
	_omega = vec3(0, 0, 0);
	
	return self;
}

- (void)setParams
{
	_g = -9.8;
	_mass = 16770;
	_thrust = 79200 * 2 * 20;
	_aoi = 5 * M_PI / 180;
	_maxaileron = 45 * M_PI / 180;
	_minaileron = -45 * M_PI / 180;
	_maxelevator = 24 * M_PI / 180;
	_minelevator = -24 * M_PI / 180;
	_wingarea = 38;
	_pitchmoi = 21935.779;
	_rollmoi = 161820.94;
	_yawmoi = 178290.06;
	_aileronarea = 0.3;
	_aileronradius = 5;
	_elevatorarea = 0.03;
	_elevatorradius = 8;
	_rudderarea = 0.3;
	_rudderradius = 8;
	_rho = 1.225;
	_liftcoeff = 1;
	_dragcoeff = 10;
	_rudderdampcoeff = 100;
	_rolldampcoeff = 50;
}

- (void)updateWithDt:(float) dt andHeadView:(mat4) headView;
{
	_facing = mat3(scale(mat4(1.f), vec3(1, -1, 1)) * inverse(headView));
	//_facing = mat3(inverse(headView));
	
	vec3 fw = _facing * vec3(0, 0, 1);
	vec3 ri = _facing * vec3(1, 0, 0);
	vec3 up = _facing * vec3(0, 1, 0);
	
	NSLog(@"fw: (%f, %f, %f)", fw.x, fw.y, fw.z);
	NSLog(@"ri: (%f, %f, %f)", ri.x, ri.y, ri.z);
	NSLog(@"up: (%f, %f, %f)", up.x, up.y, up.z);
	
	[self applyForcesWithDt: dt];
}

- (void)applyForcesWithDt:(float) dt
{
	vec3 netF(0,0,0);
	
	netF += [self fGravity];
	netF += [self fThrust];
	netF += [self fWing];
	netF += [self fDrag];
	
	vec3 a = netF / _mass;
	
	NSLog(@"a: (%f, %f, %f)", a.x, a.y, a.z);
	
	_pos += dt * _vel + 0.5f * a * dt*dt;
	_vel += dt * a;
}

- (vec3)fGravity
{
	vec3 v = vec3(0, _g * _mass, 0);
	return v;
}

- (vec3)fThrust
{
	return _facing * vec3(0, 0, _thrust);
}

- (vec3)fWing
{
	quat wingang = angleAxis(_aoi, vec3(1, 0, 0));
	vec3 wn = _facing * (wingang * vec3(0, 1, 0));
	
	vec3 v = -1.0f * _vel;
	
	return wn * _rho * _wingarea * (float) fabs(dot(v, wn)) * (dot(v, wn)) * _liftcoeff;
}

- (vec3)fDrag
{
	return -_vel * length(_vel) * _rho * _dragcoeff;
}

@end
