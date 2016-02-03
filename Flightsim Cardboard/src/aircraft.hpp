#ifndef AIRCRAFT_HPP
#define AIRCRAFT_HPP

#include "glmheaders.hpp"

class Aircraft
{
	public:
	    static const float MAX_THRUST;

		float g;
		float mass;
		float thrust;
		float aoi;
		float maxaileron;
		float minaileron;
		float maxelevator;
		float minelevator;
		float wingarea;
		float pitchmoi;
		float rollmoi;
		float yawmoi;
		float aileronarea;
		float aileronradius;
		float elevatorarea;
		float elevatorradius;
		float rudderarea;
		float rudderradius;
		float rho;
		float dragcoeff;
		float rudderdampcoeff;
		float rolldampcoeff;

		vec3 pos, velocity, omega;
		quat facing;

		void init_params();

		Aircraft();

		void update(float dt);

		void applyForces(float dt);

		vec3 fGravity();

		vec3 fWing();

		vec3 fThrust();

		vec3 fDrag();

		float tAileron();

		float tElevator();

		float tRudder();
};

#endif

