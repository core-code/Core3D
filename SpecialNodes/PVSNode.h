//
//  PVSNode.h
//  Core3D
//
//  Created by CoreCode on 13.12.09.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

@interface PVSNode : SceneNode
{
	NSArray *objects;
//	Mesh		*nodeMesh;
//	uint16_t	samplesPerCell;
}

- (id)initWithObjectArray:(NSArray *)_objects; // nodeMesh:(Mesh *)_nodeMesh samplesPerCell:(uint16_t)_samplesPerCell;
@end
