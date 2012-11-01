//
//  BatchingTextureNode.m
//  Core3D
//
//  Created by CoreCode on 03.01.12.
//  Copyright 2011 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#import "Core3D.h"
#import "BatchingTextureNode.h"


@implementation BatchingTextureNode

@synthesize size;

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithVertexBuffer:(vertex_buffer_t *)vertexBuffer andTextureAtlas:(texture_atlas_t *)textureAtlas andTextureNamed:(NSString *)textureName
{
	if ((self = [super init]))
	{
		a = textureAtlas;
		vb = vertexBuffer;

		Texture *texture = [Texture newTextureNamed:textureName];
		assert(texture);
		unsigned char *data = (unsigned char *) texture->_data;

		r = texture_atlas_get_region(a, [texture width], [texture height]);
		if (r.x < 0)
		{
			fatal("Error: couldnt fit batching texture node");
		}

		texture_atlas_set_region(a, r.x, r.y, r.width, r.height, data, r.width * 4);

		[texture release];
	}

	return self;
}

- (void)renderNode
{
	float x0 = position[0];
	float y0 = position[1] + size[1];
	float x1 = position[0] + size[0];
	float y1 = position[1];

	float u0 = r.x / (float) a->width;
	float v0 = (r.y + r.height) / (float) a->height;
	float u1 = (r.x + r.width) / (float) a->width;
	float v1 = r.y / (float) a->height;

	GLuint index = vb->vertices->size;
	GLushort indices[] = {index, index + 1, index + 2,
			index, index + 2, index + 3};
	float vertices[4][5] = {{x0, y0, 0, u0, v0},
			{x0, y1, 0, u0, v1},
			{x1, y1, 0, u1, v1},
			{x1, y0, 0, u1, v0}};

	vertex_buffer_push_back_indices(vb, indices, 6);
	vertex_buffer_push_back_vertices(vb, vertices, 4);
}

- (void)dealloc
{
	[super dealloc];
}
@end
