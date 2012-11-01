//
//  Particlesystem.h
//  Core3D
//
//  Created by CoreCode on 03.06.08.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


@interface Particlesystem : SceneNode
{
	float size, intensity, minSize, maxSize, pointSize, basePointSize;

	int particleCount;
	vector3f AABBOrigin;
	vector3f AABBExtent;
	Shader *shader;
	Texture *pointsprite;
	float *positions;
	float *velocities;
	GLenum srcBlend;
	GLenum dstBlend;
	BOOL dontDepthtest;
	vector4f blendColor;
}

@property (assign, nonatomic) float size;
@property (assign, nonatomic) float intensity;
@property (assign, nonatomic) float basePointSize;
@property (assign, nonatomic) GLenum srcBlend;
@property (assign, nonatomic) vector4f blendColor;
@property (assign, nonatomic) GLenum dstBlend;
@property (assign, nonatomic) BOOL dontDepthtest;

- (id)initWithParticleCount:(int)_particleCount andTextureNamed:(NSString *)_texture;
- (void)initParticles;
- (void)updateParticles;

@end
