//
//  ShaderNode.m
//  Core3D
//
//  Created by CoreCode on 06.09.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#import "Core3D.h"


@implementation ShaderNode

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithShader:(Shader *)_shader
{
	self = [super init];
	if (self)
	{
		shader = [_shader retain];
	}

	return self;
}

- (void)render // override render instead of implementing renderNode
{
	if ([currentRenderPass settings] & kRenderPassSetMaterial)
		[shader bind];

	[children makeObjectsPerformSelector:@selector(render)];
}

- (void)dealloc
{
	[shader release];
	[super dealloc];
}

@end
