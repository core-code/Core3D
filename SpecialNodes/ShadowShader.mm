//
//  ShadowShader.m
//  Core3D
//
//  Created by CoreCode on 16.12.10.
//  Copyright 2008 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


#import "Core3D.h"
#import "ShadowShader.h"


#undef glEnable
#undef glDisable

@implementation ShadowShader

- (id)init
{
	if ((self = [super init]))
	{
		shader = [Shader newShaderNamed:@"depthonly" withDefines:NULL withTexcoordsBound:NO andNormalsBound:NO];
	}
	return self;
}

- (void)render // override render instead of implementing renderNode
{
	glCullFace(GL_FRONT);

	myPolygonOffset(1.0f, 2.0f);
	glEnable(GL_POLYGON_OFFSET_FILL);

	[shader bind];
	[children makeObjectsPerformSelector:@selector(render)];


	glCullFace(GL_BACK);
	glDisable(GL_POLYGON_OFFSET_FILL);
}

- (void)dealloc
{
	[shader release];

	[super dealloc];
}
@end
