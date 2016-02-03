//
//  TerrainShader.fsh
//  Flightsim Cardboard
//
//  Created by Sean Purcell on 2016-01-29.
//  Copyright © 2016 Sean Purcell. All rights reserved.
//

varying vec3 Color;
varying vec3 Normal;
varying float dist;
varying vec3 Position;

uniform vec3 LIGHT_DIR;
uniform vec3 FOG_COLOR;
uniform float HORIZON;
uniform float HORIZON_COEFF;

float coeff(float x) {
	return pow(x, 2) * HORIZON_COEFF;
}

float sigmoid(float x) {
	return 1 / (1 + exp(-5 * x));
}

void main()
{
	vec3 one = vec3(1, 1, 1);
	vec3 tmp = 0.5 * one;
	tmp += 0.5 * one * (1.2 * sigmoid(Position.y / 480));
	float alpha = coeff(dist);
	alpha = min(alpha, 1);
	gl_FragColor = vec4(alpha * FOG_COLOR + (1-alpha) * tmp * Color, 1.0f);
}
