//
//  DynamicNode.h
//  CoreBreach
//
//  Created by CoreCode on 01.11.11.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//






@interface DynamicNode : SceneNode
{
	Texture *texture;
	vector<vertex> *vbuffer;
}

- (id)initWithTextureNamed:(NSString *)textureName;
- (void)addVertices:(const vertex *)vertices count:(size_t)count;

@end
