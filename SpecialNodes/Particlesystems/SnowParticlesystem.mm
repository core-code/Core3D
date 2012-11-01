//
//  SnowParticlesystem.m
//  Core3D
//
//  Created by CoreCode on 03.06.08.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see _MIT_LICENSE.txt
//


#import "Core3D.h"
#import "SnowParticlesystem.h"


inline void initParticle(float *positions, float *velocities, int i, BOOL init);

@implementation SnowParticlesystem

- (void)initOptions
{
	pointSize = 3000.0f;
	minSize = 1.0f;
	maxSize = 5.0f;
}

- (void)initParticles
{
	int i;

	for (i = 0; i < particleCount * 3; i += 3)
		initParticle(positions, velocities, i, TRUE);

	for (i = 0; i < 500; i++)
		randomBuffer[i] = cml::random_real(-0.00001f, 0.00001f);

	AABBOrigin = vector3f(0.0f, 0.0f, 0.0f);
	AABBExtent = vector3f(FLT_MAX, FLT_MAX, FLT_MAX);    // disable VFC for snow
}

- (void)updateParticles
{
	uint64_t micro = GetNanoseconds() / 1000;
	int i;

	for (i = 0; i < particleCount * 3; i += 3)
	{
		if ((globalInfo.frame % 30 == 0) && (fabsf(positions[i + 0]) > 2 || fabsf(positions[i + 1]) > 2 || fabsf(positions[i + 2]) > 2))
			initParticle(positions, velocities, i, FALSE);
		else
		{
			positions[i + 0] += velocities[i];
			positions[i + 1] += velocities[i + 1];
			positions[i + 2] += velocities[i + 2];
		}

		velocities[i] += randomBuffer[(i * globalInfo.frame) % 500];
		velocities[i + 1] += randomBuffer[((i + 1) * globalInfo.frame) % 500];
		if (velocities[i + 1] > 0.0f)
			velocities[i + 1] = 0.0f;
		velocities[i + 2] += randomBuffer[((i + 2) * globalInfo.frame) % 500];
	}
	uint64_t post = GetNanoseconds() / 1000;

	NSLog(@"took %f", (post - micro) / 1000.0);
}
@end

inline void initParticle(float *positions, float *velocities, int i, BOOL init)
{
	positions[i + 0] = cml::random_real(-2.0f, 2.0f);
	positions[i + 1] = init ? cml::random_real(-2.0f, 2.0f) : 2.0f;
	positions[i + 2] = cml::random_real(-2.0f, 2.0f);

	velocities[i + 0] = cml::random_real(-0.0001f, 0.0001f);
	velocities[i + 1] = cml::random_real(-0.0004f, -0.0006f);
	velocities[i + 2] = cml::random_real(-0.0001f, 0.0001f);
}
