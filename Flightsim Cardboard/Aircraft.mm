//
//  Aircraft.m
//  Flightsim Cardboard
//
//  Created by Sean Purcell on 2016-02-05.
//  Copyright © 2016 Sean Purcell. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OpenGLES/ES2/glext.h>
#include <GLKit/GLKit.h>

#import "glmheaders.hpp"
#import "rotation.hpp"

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
	
	float _rollControl;
	float _pitchControl;
}

- (instancetype)init
{
	self = [super init];
	if(!self) return nil;
	
	[self setParams];
	
	_pos = vec3(0, 1000.f, 1);
	_facing = quat(1.f, 0.f, 0.f, 0.f);
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
	_rudderdampcoeff = 50;
	_rolldampcoeff = 50;
}

- (void)updateWithDt:(float) dt andHeadView:(mat4) headView;
{
	[self computeControlWithView: mat3(headView)];
	[self applyForcesWithDt: dt];
}

- (void)computeControlWithView:(mat3)view;
{
	Euler angles = Euler::controlFromFacing(view);
	
	_rollControl = min(max(angles.roll / (PI / 9.f), -1.f), 1.f) * _maxaileron;
	_pitchControl = min(max(angles.pitch / (PI / 9.f), -1.f), 1.f) * _maxelevator;
	
	NSLog(@"p: %f r: %f y: %f", angles.pitchd(), angles.rolld(), angles.yawd());
}

- (void)applyForcesWithDt:(float) dt
{
	vec3 netF(0,0,0);
	
	netF += [self fGravity];
	netF += [self fThrust];
	netF += [self fWing];
	netF += [self fDrag];
	
	float rollA = [self tAileron] / _rollmoi;
	float pitchA = [self tElevator] / _pitchmoi;
	float yawA = [self tRudder] / _yawmoi;
	
	NSLog(@"pitchA: %f", pitchA);
	
	vec3 a = netF / _mass;
	vec3 alpha(pitchA, yawA, rollA);
	
	_omega += alpha * dt;
	
	if(dot(_omega, _omega) > 1e-10) {
		quat omegaVersor = angleAxis(length(_omega) * dt, _facing * _omega);
		_facing = omegaVersor * _facing;
		_facing = normalize(_facing);
	}
	
	NSLog(@"omega : %@", NSStringFromGLKVector3(GLKVector3MakeWithArray(value_ptr(_omega))));
	NSLog(@"facing: %@", NSStringFromGLKVector4(GLKVector4MakeWithArray(value_ptr(_facing))));
	
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
	quat wingang = angleAxis(-_aoi, vec3(1, 0, 0));
	vec3 wn = _facing * (wingang * vec3(0, 1, 0));
	
	vec3 v = -1.0f * _vel;
	
	return wn * _rho * _wingarea * (float) fabs(dot(v, wn)) * (dot(v, wn)) * _liftcoeff;
}

- (vec3)fDrag
{
	return -_vel * length(_vel) * _rho * _dragcoeff;
}

- (float)tAileron
{
	quat ailangl = angleAxis(-_aoi + _rollControl, vec3(1, 0, 0));
	quat ailangr = angleAxis(-_aoi - _rollControl, vec3(1, 0, 0));
	
	vec3 anl = _facing * (ailangl * vec3(0, 1, 0));
	vec3 anr = _facing * (ailangr * vec3(0, 1, 0));
	
	NSLog(@"anl : %@", NSStringFromGLKVector3(GLKVector3MakeWithArray(value_ptr(anl))));
	NSLog(@"anr : %@", NSStringFromGLKVector3(GLKVector3MakeWithArray(value_ptr(anr))));
	
	vec3 v = -_vel;
	
	vec3 vl = v + _rolldampcoeff * (_facing * vec3(0, - _omega.z * _aileronradius, 0));
	vec3 vr = v + _rolldampcoeff * (_facing * vec3(0, _omega.z * _aileronradius, 0));
	
	vec3 liftl = anl * _rho * _aileronarea * (float) fabs(dot(vl, anl)) * dot(vl, anl);
	vec3 liftr = anr * _rho * _aileronarea * (float) fabs(dot(vr, anr)) * dot(vr, anr);
	
	vec3 lt = cross(liftl, (_facing * (vec3(-_aileronradius, 0, 0))));
	vec3 rt = cross(liftr, (_facing * (vec3(_aileronradius, 0, 0))));
	
	vec3 torque = lt + rt;
	
	return dot(torque, _facing * vec3(0, 0, 1));
}

- (float)tElevator
{
	quat elangl = angleAxis(-_aoi + _pitchControl, vec3(1, 0, 0));
	
	vec3 en = _facing * (elangl * vec3(0, 1, 0));
	
	vec3 v = -_vel + _facing * vec3(0, _omega.x * _elevatorradius, 0);
	
	vec3 lift = en * _rho * _elevatorarea * (float) fabs(dot(v, en)) * dot(v, en);
	
	vec3 et = cross(lift, _facing * vec3(0, 0, _elevatorradius));
	
	return dot(et, _facing * vec3(1, 0, 0));
}

- (float)tRudder
{
	vec3 rn = _facing * vec3(1, 0, 0);
	
	vec3 v = -_vel + _facing * vec3(_omega.y * _rudderradius, 0, 0) * _rudderdampcoeff;
	
	vec3 lift = rn * _rho * _rudderarea * (float) fabs(dot(v, rn)) * dot(v, rn);
	
	vec3 rt = cross(lift, _facing * vec3(0, 0, _rudderradius));
	
	return dot(rt, _facing * vec3(0, 1, 0));
}

@end
