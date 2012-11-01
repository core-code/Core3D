//
//  VBO.h
//  Core3D
//
//  Created by CoreCode on 14.02.12.
//  Copyright 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#define VERTEX_ARRAY        0
#define TEXTURE_COORD_ARRAY 1
#define NORMAL_ARRAY        2

#define MAX_ATTRIBS         3


@interface VBO : NSObject
{
	GLuint indexVBOName, vertexVBOName, vaoName;

	BOOL attributeEnabled[MAX_ATTRIBS];

	const GLvoid *pointer[MAX_ATTRIBS];
	GLint size[MAX_ATTRIBS];
	GLenum type[MAX_ATTRIBS];
	GLboolean shouldNormalize[MAX_ATTRIBS];
	GLsizei stride[MAX_ATTRIBS];
}

- (void)setIndexBuffer:(const GLvoid *)buffer withSize:(GLsizeiptr)size;
- (void)setVertexBuffer:(const GLvoid *)buffer withSize:(GLsizeiptr)size;

- (void)setVertexAttribPointer:(const GLvoid *)pointer forIndex:(GLuint)index withSize:(GLint)size withType:(GLenum)type shouldNormalize:(GLboolean)shouldNormalize withStride:(GLsizei)stride;

+ (void)unbind;
- (void)load;
- (void)bind;

@end
