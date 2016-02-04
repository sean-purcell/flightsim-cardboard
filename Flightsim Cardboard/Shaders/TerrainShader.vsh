//
//  TerrainShader.vsh
//  Flightsim Cardboard
//
//  Created by Sean Purcell on 2016-01-29.
//  Copyright © 2016 Sean Purcell. All rights reserved.
//

precision mediump float;

attribute mediump vec3 position;
attribute mediump vec3 color;

varying vec3 Color;
varying float dist;
varying vec3 Position;

uniform mat4 projView;

void main()
{
	Color = color;
	
	gl_Position = projView * vec4(position, 1.0);
	dist = sqrt(gl_Position.z * gl_Position.z + gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
	Position = position;
}
