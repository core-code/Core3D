//
//  LODNode.h
//  Core3D
//
//  Created by CoreCode on 27.01.10.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see _MIT_LICENSE.txt
//


@interface LODNode : SceneNode
{
	vector3f center;
	float radius;
	float factors[2];
}

- (id)initWithOctreesNamed:(NSArray *)_names andFactor:(float)_factor;

@end
