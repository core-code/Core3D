//
//  Skybox.h
//  Core3D
//
//  Created by CoreCode on 09.12.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


@interface Skybox : SceneNode
{
	Texture *surroundTexture, *upTexture, *downTexture;
	VBO *vbo;
	uint16_t size;
}

- (id)initWithSurroundTextureNamed:(NSString *)surroundName;
- (id)initWithSurroundTextureNamed:(NSString *)surroundName andDownTextureNamed:(NSString *)downName;
- (id)initWithSurroundTextureNamed:(NSString *)surroundName andUpTextureNamed:(NSString *)upName;
- (id)initWithSurroundTextureNamed:(NSString *)surroundName andUpTextureNamed:(NSString *)upName andDownTextureNamed:(NSString *)downName;

@property (assign, nonatomic) uint16_t size;

@end
