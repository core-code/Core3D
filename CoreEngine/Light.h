//
//  Light.h
//  Core3D
//
//  Created by CoreCode on 22.11.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


@interface Light : SceneNode
{
	vector4f lightDiffuseColor, lightSpecularColor, lightAmbientColor;
	float linearAttenuation;
}

@property (assign, nonatomic) float linearAttenuation;
@property (assign, nonatomic) vector4f lightDiffuseColor;
@property (assign, nonatomic) vector4f lightSpecularColor;
@property (assign, nonatomic) vector4f lightAmbientColor;

CPPPROPERTYSUPPORT_V4_H(lightDiffuseColor)
CPPPROPERTYSUPPORT_V4_H(lightSpecularColor)
CPPPROPERTYSUPPORT_V4_H(lightAmbientColor)

@end
