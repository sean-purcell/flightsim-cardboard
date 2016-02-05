//
//  TerrainShader.vsh
//  Flightsim Cardboard
//
//  Created by Sean Purcell on 2016-01-29.
//  Copyright © 2016 Sean Purcell. All rights reserved.
//

attribute highp vec3 position;
attribute lowp vec3 color;

varying lowp vec3 Color;
varying lowp float dist;
varying lowp float height;

uniform highp mat4 projView;

void main()
{
	Color = color;
	
	gl_Position = projView * vec4(position, 1.0);
	dist = sqrt(gl_Position.z * gl_Position.z + gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
	height = position.y;
}
