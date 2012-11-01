//
//  VBO.m
//  Core3D
//
//  Created by CoreCode on 14.02.12.
//  Copyright 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#import "Core3D.h"
#import "VBO.h"


#undef glEnableVertexAttribArray
#undef glDisableVertexAttribArray
//#ifdef __APPLE__
//#define USE_VAO
//#endif

@implementation VBO

- (void)setIndexBuffer:(const GLvoid *)buffer withSize:(GLsizeiptr)_size
{
	if (!indexVBOName)
		glGenBuffers(1, &indexVBOName);
	assert(indexVBOName);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexVBOName);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, _size, buffer, GL_STATIC_DRAW);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

- (void)setVertexBuffer:(const GLvoid *)buffer withSize:(GLsizeiptr)_size
{
	if (!vertexVBOName)
		glGenBuffers(1, &vertexVBOName);
	glBindBuffer(GL_ARRAY_BUFFER, vertexVBOName);
	glBufferData(GL_ARRAY_BUFFER, _size, buffer, GL_STATIC_DRAW);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
}

- (void)setVertexAttribPointer:(const GLvoid *)_pointer forIndex:(GLuint)index withSize:(GLint)_size withType:(GLenum)_type shouldNormalize:(GLboolean)_shouldNormalize withStride:(GLsizei)_stride
{
	assert(index >= 0 && index < MAX_ATTRIBS);

	attributeEnabled[index] = YES;
	pointer[index] = _pointer;
	size[index] = _size;
	type[index] = _type;
	shouldNormalize[index] = _shouldNormalize;
	stride[index] = _stride;
}

- (void)load
{
	assert(vertexVBOName && indexVBOName);
	assert(attributeEnabled[VERTEX_ARRAY] || attributeEnabled[TEXTURE_COORD_ARRAY] || attributeEnabled[NORMAL_ARRAY]);

#ifdef USE_VAO
	glGenVertexArrays(1, &vaoName);
	glBindVertexArray(vaoName);


	glBindBuffer(GL_ARRAY_BUFFER, vertexVBOName);

	for (GLuint i = 0; i < MAX_ATTRIBS; i++)
	{
		if (attributeEnabled[i] == YES)
		{
			glEnableVertexAttribArray(i);
			glVertexAttribPointer(i, size[i], type[i], shouldNormalize[i], stride[i], pointer[i]);
		}
		else
			glDisableVertexAttribArray(i);
	}

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexVBOName);


	glBindVertexArray(globalInfo.defaultVAOName);

//    glBindBuffer(GL_ARRAY_BUFFER, 0);
//    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

	currentVBO = nil;
#endif
}

- (void)bind
{
	if (currentVBO == self)
		return;

#ifdef USE_VAO
	assert(vaoName);
	glBindVertexArray(vaoName);
#else
    glBindBuffer(GL_ARRAY_BUFFER, vertexVBOName);
    
    for (int i = 0; i < MAX_ATTRIBS; i++)
    {
        if (attributeEnabled[i] == YES && ((i != TEXTURE_COORD_ARRAY) || ((i == TEXTURE_COORD_ARRAY) &&   
                                                                        ([currentRenderPass settings] & kRenderPassUseTexture) && 
                                                                        (!globalSettings.disableTex))))
        {
            myEnableVertexAttribArray(i);
        	glVertexAttribPointer(i, size[i], type[i], shouldNormalize[i], stride[i],  pointer[i]);
        }
        else
            myDisableVertexAttribArray(i);
    }
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexVBOName);
#endif
}

+ (void)unbind
{
#ifdef USE_VAO
	glBindVertexArray(globalInfo.defaultVAOName);
#else
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
#endif

	currentVBO = nil;
}

- (void)dealloc
{
	if (currentVBO == self)
	{
		[VBO unbind];
	}
#ifdef USE_VAO
	glDeleteVertexArrays(1, &vaoName);
#endif
	glDeleteBuffers(1, &indexVBOName);
	glDeleteBuffers(1, &vertexVBOName);

	[super dealloc];
}
@end
