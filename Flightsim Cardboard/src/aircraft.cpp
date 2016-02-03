#include <cmath>

#include "glmheaders.hpp"

#include "aircraft.hpp"
#include "util.hpp"

extern float up, down, left, right;

const float Aircraft::MAX_THRUST = 792000 * 2;

void Aircraft::init_params() {
	g = -9.8;
	mass = 16770;
	thrust = 79200 * 2;
	aoi = 5 * M_PI / 180;
	maxaileron = 45 * M_PI / 180;
	minaileron = -45 * M_PI / 180;
	maxelevator = 24 * M_PI / 180;
	minelevator = -24 * M_PI / 180;
	wingarea = 38;
	pitchmoi = 21935.779;
	rollmoi = 161820.94;
	yawmoi = 178290.06;
	aileronarea = 0.3;
	aileronradius = 5;
	elevatorarea = 0.03;
	elevatorradius = 8;
	rudderarea = 0.3;
	rudderradius = 8;
	rho = 1.225;
	dragcoeff = 0.2;
	rudderdampcoeff = 100;
	rolldampcoeff = 50;
}

Aircraft::Aircraft(){
	init_params();

	pos = vec3(1, 1000, 1);
	facing = quat(1, 0, 0, 0);	//orientation
	velocity = vec3(0, 0, 500);
	omega = vec3(0, 0, 0);
}

void Aircraft::update(float dt){
	applyForces(dt);
}

void Aircraft::applyForces(float dt) {
	vec3 netF(0, 0, 0);

	netF = netF + fGravity();
	netF = netF + fWing();
	netF = netF + fThrust();
	netF = netF + fDrag();

	float rollA = tAileron() / rollmoi;
	float pitchA = tElevator() / pitchmoi;
	float yawA = tRudder() / yawmoi;

	vec3 accel = netF / mass;

	this->pos = this->pos + this->velocity * dt + accel * (0.5f * dt * dt);
	this->velocity = this->velocity + accel * dt;

	vec3 alpha(pitchA, yawA, rollA);

	omega = omega + alpha * dt;

	if(dot(omega, omega) > 1e-10) {
		quat omegaVersor = angleAxis(length(omega) * dt, facing * omega);
		facing = omegaVersor * facing;
		facing = normalize(facing);
	}

	//std::cout << "s:" << this->pos << ", v:" << this->velocity << ", a:" << accel << ", f:" << (facing * (vec3(0, 0, 1))) << std::endl;
}

vec3 Aircraft::fGravity() {
	return vec3(0, g * mass, 0);
}

vec3 Aircraft::fWing() {
	quat wingang = angleAxis(aoi, vec3(-1, 0, 0));
	vec3 wn = facing * (wingang * vec3(0, 1, 0));
	vec3 v = -1.0f * this->velocity;

	vec3 lift = wn * rho * wingarea * (float) fabs(dot(v, wn)) * (dot(v, wn));
	return lift;
}

vec3 Aircraft::fThrust() {
	vec3 fw = facing * (vec3(0, 0, 1));
	return fw * thrust;
}

vec3 Aircraft::fDrag() {
	vec3 bw = facing * (vec3(0, 0, -1));
	return bw * (dot(velocity, bw)) * (dot(velocity, bw)) * rho * dragcoeff;
}

float Aircraft::tAileron() {
	float effect = left * maxaileron + right * minaileron;
	quat ailangl = angleAxis(-aoi - effect, vec3(-1, 0, 0));
	quat ailangr = angleAxis(aoi - effect, vec3( 1, 0, 0));

	vec3 anl = facing * (ailangl * (vec3(0, 1, 0)));
	vec3 anr = facing * (ailangr * (vec3(0, 1, 0)));

	vec3 v = this->velocity * -1.0f;
	vec3 vl = v + rolldampcoeff * (facing * (vec3(0, -this->omega.z * aileronradius, 0)));
	vec3 vr = v + rolldampcoeff * (facing * (vec3(0, this->omega.z * aileronradius, 0)));

	vec3 liftl = anl * rho * aileronarea * (float) fabs(dot(vl, anl)) * (dot(vl, anl));
	vec3 liftr = anr * rho * aileronarea * (float) fabs(dot(vr, anr)) * (dot(vr, anr));

	vec3 lt = cross(liftl, (facing * (vec3(-aileronradius, 0, 0))));
	vec3 rt = cross(liftr, (facing * (vec3(aileronradius, 0, 0))));

	vec3 torque = lt + rt;
	return dot(torque, facing * (vec3(0, 0, 1)));
}

float Aircraft::tElevator() {
	float effect = -up * minelevator + -down * maxelevator;
	quat elangl = angleAxis(-effect, vec3(1, 0, 0));

	vec3 en = facing * (elangl * (vec3(0, 1, 0)));

	vec3 v = this->velocity * -1.0f
		+ facing * (vec3(0, omega.x * elevatorradius, 0));

	vec3 lift = en * rho * elevatorarea * (float) fabs(dot(v, en)) * (dot(v, en));

	vec3 et = cross(lift, (facing * (vec3(0, 0, elevatorradius))));

	return dot(et, (facing * (vec3(1, 0, 0))));
}

float Aircraft::tRudder() {
	vec3 rn = facing * (vec3(1, 0, 0));

	vec3 v = this->velocity * -1.0f
		+ facing * (vec3(omega.y * rudderradius, 0, 0)) *
			rudderdampcoeff;

	vec3 lift = rn * rho * rudderarea * (float) fabs(dot(v, rn)) * (dot(v, rn));

	vec3 rt = cross(lift, facing * (vec3(0, 0, rudderradius)));

	return dot(rt, facing * (vec3(0, 1, 0)));
}

