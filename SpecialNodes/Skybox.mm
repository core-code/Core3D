//
//  Skybox.m
//  Core3D
//
//  Created by CoreCode on 09.12.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


#import "Core3D.h"
#import "Skybox.h"


@implementation Skybox

@synthesize size;

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithSurroundTextureNamed:(NSString *)surroundName
{
	return [self initWithSurroundTextureNamed:surroundName andUpTextureNamed:nil andDownTextureNamed:nil];
}

- (id)initWithSurroundTextureNamed:(NSString *)surroundName andDownTextureNamed:(NSString *)downName
{
	return [self initWithSurroundTextureNamed:surroundName andUpTextureNamed:nil andDownTextureNamed:downName];
}

- (id)initWithSurroundTextureNamed:(NSString *)surroundName andUpTextureNamed:(NSString *)upName
{
	return [self initWithSurroundTextureNamed:surroundName andUpTextureNamed:upName andDownTextureNamed:nil];
}

- (id)initWithSurroundTextureNamed:(NSString *)surroundName andUpTextureNamed:(NSString *)upName andDownTextureNamed:(NSString *)downName
{
	if ((self = [super init]))
	{
		surroundTexture = [Texture newTextureNamed:surroundName];
		[surroundTexture setWrapS:GL_CLAMP_TO_EDGE];
		[surroundTexture setWrapT:GL_CLAMP_TO_EDGE];
		[surroundTexture load];

		if (upName)
		{
			upTexture = [Texture newTextureNamed:upName];
			[upTexture setWrapS:GL_CLAMP_TO_EDGE];
			[upTexture setWrapT:GL_CLAMP_TO_EDGE];
			[upTexture load];
		}

#ifndef TARGET_OS_IPHONE
        if (downName)
        {
            downTexture = [Texture newTextureNamed:downName];
            [downTexture setWrapS:GL_CLAMP_TO_EDGE];
            [downTexture setWrapT:GL_CLAMP_TO_EDGE];
            [downTexture load];
        }
#endif

		size = iOS ? 6800 : 8000;   // dunno


		const GLushort indices[] = {0, 1, 2, 1, 2, 3, 4, 5, 6, 5, 6, 7, 8, 9, 10, 9, 10, 11, 12, 13, 14, 13, 14, 15,
				16, 17, 18, 17, 18, 19,
				20, 21, 22, 21, 22, 23};

		const GLshort vertices[] = {
				-size, -size, size, -size, -size, -size, -size, size, size, -size, size, -size,    // Left Face
				size, size, -size, size, -size, -size, size, size, size, size, -size, size,        // Right face
				-size, size, -size, -size, -size, -size, size, size, -size, size, -size, -size,        // Back Face
				size, -size, size, -size, -size, size, size, size, size, -size, size, size,    // Front Face
				size, -size, -size, -size, -size, -size, size, -size, size, -size, -size, size,    // Bottom Face
				-size, size, size, -size, size, -size, size, size, size, size, size, -size};    // Top Face

		const GLfloat texCoords[] = {
				(0.5f), (0.0f), (1.0f), (0.0f), (0.5f), (0.5f), (1.0f), (0.5f),    // Left Face
				(0.5f), (1.0f), (0.5f), (0.5f), (1.0f), (1.0f), (1.0f), (0.5f),    // Right face
				(0.0f), (1.0f), (0.0f), (0.5f), (0.5f), (1.0f), (0.5f), (0.5f),    // Back Face
				(0.0f), (0.0f), (0.5f), (0.0f), (0.0f), (0.5f), (0.5f), (0.5f),    // Front Face
				(1.0f), (1.0f), (1.0f), (0.0f), (0.0f), (1.0f), (0.0f), (0.0f),    // Bottom Face
				(0.0f), (1.0f), (1.0f), (1.0f), (0.0f), (0.0f), (1.0f), (0.0f)};    // Top Face

		char *vbuffer = (char *) malloc(sizeof(vertices) + sizeof(texCoords));
		memcpy(vbuffer, vertices, sizeof(vertices));
		memcpy(vbuffer + sizeof(vertices), texCoords, sizeof(texCoords));

		vbo = [[VBO alloc] init];

		[vbo setIndexBuffer:indices withSize:36 * sizeof(GLushort)];
		[vbo setVertexBuffer:vbuffer withSize:sizeof(vertices) + sizeof(texCoords)];
		[vbo setVertexAttribPointer:(const GLvoid *) 0
		                   forIndex:VERTEX_ARRAY withSize:3 withType:GL_SHORT shouldNormalize:GL_FALSE withStride:0];
		[vbo setVertexAttribPointer:(const GLvoid *) (sizeof(GLshort) * 72)
		                   forIndex:TEXTURE_COORD_ARRAY withSize:2 withType:GL_FLOAT shouldNormalize:GL_FALSE withStride:0];
		[vbo load];
		free(vbuffer);
	}
	return self;
}

- (void)renderNode
{
	if ([currentRenderPass settings] != kMainRenderPass)
		return;

	vector3f cp = [currentCamera position];
	matrix44f_c svm = [currentCamera viewMatrix];


	[currentCamera push];
	[currentCamera setPosition:vector3f(0.0f, 0.0f, 0.0f)];
	[currentCamera identity];
	[currentCamera transform];
	[currentCamera setPosition:cp];



	myEnableBlendParticleCullDepthtestDepthwrite(NO, NO, NO, YES, YES);


	[vbo bind];
	[surroundTexture bind];

	globalMaterial.color = vector4f(1.0f, 1.0f, 1.0f, 1.0f);

	assert(currentShader);
	[currentShader prepare];

	glDrawElements(GL_TRIANGLES, 24, GL_UNSIGNED_SHORT, (const GLushort *) 0);


	globalInfo.drawCalls++;
	/*DRAW_CALL*/

	if (upTexture)
	{
		[upTexture bind];
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, (const GLushort *) 24);
		globalInfo.drawCalls++;
		/*DRAW_CALL*/
	}
	if (downTexture)
	{
		[downTexture bind];
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, (const GLushort *) 30);
		globalInfo.drawCalls++;
		/*DRAW_CALL*/
	}

	[currentCamera pop];
	[currentCamera setViewMatrix:svm];
//   currentRenderPass.settings = savedSettings;
}

- (void)dealloc
{
	[vbo release];
	[surroundTexture release];
	[upTexture release];
	[downTexture release];

	[super dealloc];
}
@end
