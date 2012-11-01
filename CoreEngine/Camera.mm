//
//  Camera.m
//  Core3D
//
//  Created by CoreCode on 21.11.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


#import "Core3D.h"


@implementation Camera


@synthesize fov, nearPlane, farPlane, projectionMatrix, viewMatrix, relativeModeTargetFactor;

- (id)init
{
	if ((self = [super init]))
	{
		fov = 80.0f;
		nearPlane = 0.5f;
		farPlane = 14000.0f;
		relativeModeTargetFactor = vector3f(1, 1, 1);

		[self addObserver:self forKeyPath:@"fov" options:NSKeyValueObservingOptionNew context:NULL];
		[self addObserver:self forKeyPath:@"nearPlane" options:NSKeyValueObservingOptionNew context:NULL];
		[self addObserver:self forKeyPath:@"farPlane" options:NSKeyValueObservingOptionNew context:NULL];

		modelViewMatrices.push_back(cml::identity_transform<4, 4>());
	}

	return self;
}

- (void)dealloc
{
	[self removeObserver:self forKeyPath:@"fov"];
	[self removeObserver:self forKeyPath:@"nearPlane"];
	[self removeObserver:self forKeyPath:@"farPlane"];

	[super dealloc];
}

- (vector3f)getLookAt // TODO: get rid of this method and find a proper solution for what it is trying to solve
{
	axisConfigurationEnum stored = axisConfiguration;
	axisConfiguration = kYXZRotation;
	vector3f bla = [super getLookAt];
	axisConfiguration = stored;
	return bla;
}

- (void)reshapeNode:(CGSize)_size
{
	size = _size;
	[self updateProjection];
}

- (void)transform
{
	[self rotate:-rotation withConfig:axisConfiguration]; // TODO: camera axis config broken
	[self translate:-position];

	if (relativeModeTarget != nil)
	{
		vector3f rot = component_mult3([relativeModeTarget rotation], relativeModeTargetFactor);
		[self rotate:-rot withConfig:relativeModeAxisConfiguration];
		[self translate:-[relativeModeTarget position]];
	}

	viewMatrix = modelViewMatrices.back();

#ifndef DISABLE_SOUND
	if (currentRenderPass.settings == kMainRenderPass)
	{
		static uint64_t frame = 666;

		if (frame != globalInfo.frame) // once per frame, regardless of the number of main passes
		{
			vector3f pos = [relativeModeTarget position] + position;
			alListenerfv(AL_POSITION, pos.data());

			vector3f up = [self getUp];
			vector3f forward = [self getLookAt];
			ALfloat orientation[6] = {forward[0], forward[1], forward[2], up[0], up[1], up[2]};
			alListenerfv(AL_ORIENTATION, orientation);

			frame = globalInfo.frame;
		}
	}
#endif
}

- (float)getAspectRatio
{
	return (float) (size.width / size.height);
}

- (void)updateProjection
{
	if (size.width && size.height)
		matrix_perspective_yfov_RH(projectionMatrix, cml::rad(fov), (float) (size.width / size.height), nearPlane, farPlane, cml::z_clip_neg_one);
	else
		cml::identity_transform(projectionMatrix);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self updateProjection];
}

- (matrix44f_c)modelViewMatrix
{
	return modelViewMatrices.back();
}

- (void)identity
{
	cml::identity_transform(modelViewMatrices.back());
}

- (void)scale:(float)_scale
{
	matrix44f_c m;
	matrix_uniform_scale(m, _scale);
	modelViewMatrices.back() *= m;
}

- (void)translate:(vector3f)tra
{
	matrix44f_c m;
	matrix_translation(m, tra);
	modelViewMatrices.back() *= m;
}

- (void)rotate:(vector3f)rot withConfig:(axisConfigurationEnum)axisRotation
{
	// this allows us to configure per-node the rotation order and axis to ignore (which is mostly useful for target mode)
	for (uint8_t i = 0; i < 3; i++)    
	{
		uint8_t axis = (axisRotation >> (i * 2)) & 3;

		if ((axis != kDisabledAxis) && (rot[axis] != 0))
			matrix_rotate_about_local_axis(modelViewMatrices.back(), axis, cml::rad(rot[axis]));
	}
}

- (void)push
{
	matrix44f_c m = modelViewMatrices.back();
	modelViewMatrices.push_back(m);
}

- (void)pop
{
	modelViewMatrices.pop_back();
}

#ifdef __COCOTRON__
// KVO broken
- (void)setFov:(float)_fov
{
    [self updateProjection];
    fov = _fov;
}

- (void)setNearPlane:(float)_nearPlane
{
    [self updateProjection];
    nearPlane = _nearPlane;
}

- (void)setFarPlane:(float)_farPlane
{
    [self updateProjection];
    farPlane = _farPlane;
}
#endif
@end
