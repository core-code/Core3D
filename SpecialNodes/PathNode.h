//
//  PathNode.h
//  Core3D
//
//  Created by CoreCode on 07.05.08.
//  Copyright 2008 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#define Y_OFFSET 3.0f

@interface PathNode : SceneNode
{
	float *trackPath;
	uint16_t trackPoints;
}

@property (assign, nonatomic) uint16_t trackPoints;

- (id)initWithContentsOfURL:(NSURL *)_url;

@end
