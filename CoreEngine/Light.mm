//
//  Light.m
//  Core3D
//
//  Created by CoreCode on 22.11.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


#import "Core3D.h"


@implementation Light

@synthesize lightDiffuseColor, lightSpecularColor, lightAmbientColor, linearAttenuation;

- (id)init
{
	if ((self = [super init]))
	{
		linearAttenuation = 0.0f;
		lightAmbientColor = vector4f(0.0f, 0.0f, 0.0f, 1.0f);
		lightDiffuseColor = vector4f(0.99f, 0.99f, 0.99f, 1.0f);
		lightSpecularColor = vector4f(0.99f, 0.99f, 0.99f, 1.0f);
	}
	return self;
}

// for editor because bindings don't work for c++ properties
CPPPROPERTYSUPPORT_V4_M(lightDiffuseColor, LightDiffuseColor)
CPPPROPERTYSUPPORT_V4_M(lightSpecularColor, LightSpecularColor)
CPPPROPERTYSUPPORT_V4_M(lightAmbientColor, LightAmbientColor)

@end