//
//  SphereParticlesystem.m
//  Core3D
//
//  Created by CoreCode on 15.06.08.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


#import "Core3D.h"
#import "SphereParticlesystem.h"


@implementation SphereParticlesystem

- (void)initOptions
{
	pointSize = 0.0f;
	basePointSize = 150.0f;
}

- (void)initParticles
{
	int i;

	for (i = 0; i < particleCount * 3; i += 3)
	{
		positions[i + 0] = 0.0;
		positions[i + 1] = 0.0;
		positions[i + 2] = 0.0;

		vector3f u;
		random_unit(u);
		u *= cml::random_real(0.002, 0.02);
		velocities[i + 0] = u[0];
		velocities[i + 1] = u[1];
		velocities[i + 2] = u[2];
	}

	AABBOrigin = vector3f(-0.25, -0.25, -0.25);
	AABBExtent = vector3f(0.25, 0.25, 0.25);
}

- (void)updateParticles
{
	int i;
	for (i = 0; i < particleCount * 3; i += 3)
	{
		const vector3fe pos(&positions[i]);
		if (pos.length() > 0.25)
		{
			positions[i + 0] = 0.0;
			positions[i + 1] = 0.0;
			positions[i + 2] = 0.0;
		}
		else
		{
			positions[i + 0] += velocities[i];
			positions[i + 1] += velocities[i + 1];
			positions[i + 2] += velocities[i + 2];
		}
	}

	vector3f dist = [currentCamera aggregatePosition] - [self aggregatePosition];
	pointSize = (basePointSize / dist.length());
}
@end
