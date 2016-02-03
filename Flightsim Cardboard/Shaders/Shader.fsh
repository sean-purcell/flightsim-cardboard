//
//  Shader.fsh
//  Flightsim Cardboard
//
//  Created by Sean Purcell on 2016-01-29.
//  Copyright © 2016 Sean Purcell. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
	//gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
}
