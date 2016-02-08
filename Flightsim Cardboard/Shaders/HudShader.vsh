//
//  TerrainShader.vsh
//  Flightsim Cardboard
//
//  Created by Sean Purcell on 2016-01-29.
//  Copyright © 2016 Sean Purcell. All rights reserved.
//

attribute highp vec3 position;
attribute mediump vec2 texcoord;

varying mediump vec2 Texcoord;

uniform highp mat4 projView;

void main()
{
	gl_Position = projView * vec4(position, 1.0);
	Texcoord = texcoord;
}
