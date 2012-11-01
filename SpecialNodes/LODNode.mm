//
//  LODNode.mm
//  Core3D
//
//  Created by CoreCode on 27.01.10.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see _MIT_LICENSE.txt
//


#import "Core3D.h"
#import "LODNode.h"


@implementation LODNode

- (id)initWithOctreesNamed:(NSArray *)_names andFactor:(float)_factor
{
	if ((self = [super init]))
	{
		for (NSString *n in _names)
			[children addObject:[[[Mesh alloc] initWithOctreeNamed:n] autorelease]];

		assert([_names count] == 2);

		factors[0] = _factor;
		factors[1] = 999999;

//		[(Mesh *)[children objectAtIndex:0] setColor:vector4f(1.0, 1.0, 1.0, 1.0)];
//		[(Mesh *)[children objectAtIndex:1] setColor:vector4f(1.0, 0.0, 0.0, 1.0)];
//		[(Mesh *)[children objectAtIndex:2] setColor:vector4f(0.0, 1.0, 0.0, 1.0)];
//		[(Mesh *)[children objectAtIndex:3] setColor:vector4f(0.0, 0.0, 1.0, 1.0)];

		center = [(Mesh *) [children objectAtIndex:0] center];
		radius = [(Mesh *) [children objectAtIndex:0] radius];
	}
	return self;
}

- (void)render // override render instead of implementing renderNode
{
	vector3f ro = center + [(SceneNode *) [children objectAtIndex:0] position];
	vector3f cp = [currentCamera position];
	float distFactor = vector3f(cp - ro).length() / radius;



	for (uint8_t i = 0; i < 2; i++)
	{
		if (distFactor < factors[i])
		{
			[[children objectAtIndex:i] render];
			break;
		}
	}
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
	SEL aSelector = [invocation selector];

	if ([[children objectAtIndex:0] respondsToSelector:aSelector])
		[invocation invokeWithTarget:[children objectAtIndex:0]];
	else
		[self doesNotRecognizeSelector:aSelector];
}
@end

