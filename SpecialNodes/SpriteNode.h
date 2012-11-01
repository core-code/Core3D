//
//  SpriteNode.h
//  Core3D
//
//  Created by CoreCode on 14.04.11.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


@interface SpriteNode : SceneNode
{
	vector3f velocity;
	Texture *texture;
	float size;
	GLuint additionalBlendFactorPos;
	float additionalBlendFactor;
}

@property (assign, nonatomic) vector3f velocity;
@property (assign, nonatomic) float size;
@property (assign, nonatomic) float additionalBlendFactor;

- (id)initWithTextureNamed:(NSString *)textureName;

@end
