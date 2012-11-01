//
//  BatchingTextureNode.h
//  Core3D
//
//  Created by CoreCode on 03.01.12.
//  Copyright 2011 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#include "freetype-gl.h"
#include "font-manager.h"
#include "vertex-buffer.h"
#include "markup.h"


@interface BatchingTextureNode : SceneNode
{
	vertex_buffer_t *vb;
	texture_atlas_t *a;

	ivec4 r;

	vector2f size;
}

@property (assign, nonatomic) vector2f size;

- (id)initWithVertexBuffer:(vertex_buffer_t *)vertexBuffer andTextureAtlas:(texture_atlas_t *)textureAtlas andTextureNamed:(NSString *)textureName;

@end
