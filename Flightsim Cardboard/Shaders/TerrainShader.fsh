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
uniform vec3 SKY_COLOR;
uniform float HORIZON;

float coeff(float x) {
	return pow(x / HORIZON, 2.0);
}

float sigmoid(float x) {
	return 1.0 / (1.0 + exp(-5.0 * x));
}

void main()
{
	float tmp = 0.5;
	tmp += 0.5 * (1.2 * sigmoid(Position.y / 480.0));
	//tmp += 0.5 * Position.y / 480.0;
	float alpha = coeff(dist);
	alpha = max(0.0, min(alpha, 1.0));
	gl_FragColor = vec4(alpha * SKY_COLOR + (1.0-alpha) * tmp * Color, 1.0);
}
