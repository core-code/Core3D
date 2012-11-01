//
//  FireParticlesystem.m
//  Core3D
//
//  Created by CoreCode on 10.01.08.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


#import "Core3D.h"
#import "FireParticlesystem.h"


@implementation FireParticlesystem

- (void)initOptions
{
	pointSize = 0.0f;
	basePointSize = 30.0f;
}

- (void)initParticles
{
	int i;

	for (i = 0; i < particleCount * 3; i += 3)
	{
		positions[i + 0] = cml::random_real(-0.03f, 0.03f);
		positions[i + 1] = cml::random_real(-0.03f, 0.03f);
		positions[i + 2] = cml::random_real(-0.09f, 0.09f);

		velocities[i + 0] = cml::random_real(-0.009f, 0.009f);
		velocities[i + 1] = cml::random_real(-0.009f, 0.009f);
		velocities[i + 2] = cml::random_real(0.03f, 0.12f);
	}

	AABBOrigin = vector3f(0.0f, 0.0f, 0.195f);
	AABBExtent = vector3f(0.201f, 0.201f, 0.285f);
}

- (void)updateParticles
{
	int i;
	for (i = 0; i < particleCount * 3; i += 3)
	{
		if (positions[i + 2] > 0.48)
		{
			positions[i + 0] = cml::random_real(-0.03f, 0.03f);
			positions[i + 1] = cml::random_real(-0.03f, 0.03f);
			positions[i + 2] = cml::random_real(-0.09f, 0.09f);
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

//    dispatch_apply(particleCount * 3, dispatch_get_global_queue(0, 0), ^(size_t i) {
//      if (positions[i+2] > 0.48)
//		{
//			positions[i+0] = cml::random_real(-0.03f, 0.03f);
//			positions[i+1] = cml::random_real(-0.03f, 0.03f);
//			positions[i+2] = cml::random_real(-0.09f, 0.09f);
//		}
//		else
//		{
//			positions[i+0] += velocities[i];
//			positions[i+1] += velocities[i+1];
//			positions[i+2] += velocities[i+2];
//		}
//    });
}

@end
