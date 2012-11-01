//
//  Camera.h
//  Core3D
//
//  Created by CoreCode on 21.11.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


@interface Camera : SceneNode
{
	float fov, nearPlane, farPlane;

	CGSize size;

	matrix44f_c projectionMatrix;
	matrix44f_c viewMatrix;
	vector<matrix44f_c> modelViewMatrices;
	vector3f relativeModeTargetFactor;
}

@property (assign, nonatomic) float fov;
@property (assign, nonatomic) float nearPlane;
@property (assign, nonatomic) float farPlane;
@property (assign, nonatomic) matrix44f_c projectionMatrix;
@property (assign, nonatomic) matrix44f_c viewMatrix;
@property (assign, nonatomic) vector3f relativeModeTargetFactor;

- (void)updateProjection;

- (matrix44f_c)modelViewMatrix;

- (void)push;
- (void)pop;
- (void)identity;
- (void)scale:(float)_scale;
- (void)translate:(vector3f)tra;
- (void)rotate:(vector3f)rot withConfig:(axisConfigurationEnum)axisRotation;
- (float)getAspectRatio;

@end
