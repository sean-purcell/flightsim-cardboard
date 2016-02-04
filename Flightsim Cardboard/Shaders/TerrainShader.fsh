//
//  TerrainShader.fsh
//  Flightsim Cardboard
//
//  Created by Sean Purcell on 2016-01-29.
//  Copyright © 2016 Sean Purcell. All rights reserved.
//

precision mediump float;

varying vec3 Color;
varying float dist;
varying vec3 Position;

uniform vec3 LIGHT_DIR;
uniform vec3 FOG_COLOR;
uniform float HORIZON;

float coeff(float x) {
	return pow(x / HORIZON, 2.0);
}

float sigmoid(float x) {
	return 1.0 / (1.0 + exp(-5.0 * x));
}

void main()
{
	vec3 one = vec3(1, 1, 1);
	vec3 tmp = 0.5 * one;
	tmp += 0.5 * one * (1.2 * sigmoid(Position.y / 480.0));
	float alpha = coeff(dist);
	alpha = min(alpha, 1.0);
	gl_FragColor = vec4(alpha * FOG_COLOR + (1.0-alpha) * tmp * Color, 1.0);
}
