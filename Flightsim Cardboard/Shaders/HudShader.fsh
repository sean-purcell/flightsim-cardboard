//
//  TerrainShader.fsh
//  Flightsim Cardboard
//
//  Created by Sean Purcell on 2016-01-29.
//  Copyright © 2016 Sean Purcell. All rights reserved.
//

precision mediump float;

varying vec2 Texcoord;

uniform sampler2D tex;
uniform vec4 hudColor;

void main()
{
	float alpha = texture2D(tex, Texcoord).a;
	gl_FragColor = hudColor * alpha;
}
