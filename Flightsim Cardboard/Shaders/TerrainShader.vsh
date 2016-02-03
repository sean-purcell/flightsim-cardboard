//
//  TerrainShader.vsh
//  Flightsim Cardboard
//
//  Created by Sean Purcell on 2016-01-29.
//  Copyright © 2016 Sean Purcell. All rights reserved.
//

attribute vec3 position;
attribute vec3 color;
attribute vec3 normal;

varying vec3 Color;
varying vec3 Normal;
varying float dist;
varying vec3 Position;

uniform mat4 proj;
uniform mat4 view;

void main()
{
	Color = color;
	Normal = normal;
	
	gl_Position = proj * view * vec4(position, 1.0);
	dist = sqrt(gl_Position.z * gl_Position.z + gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
	Position = position;
}
