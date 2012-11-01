//
//  SpriteNode.m
//  Core3D
//
//  Created by CoreCode on 14.04.11.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#import "Core3D.h"
#import "SpriteNode.h"


@implementation SpriteNode

@synthesize size, additionalBlendFactor, velocity;

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithTextureNamed:(NSString *)textureName
{
	if ((self = [super init]))
	{
		texture = [Texture newTextureNamed:textureName];
		[texture load];

		size = 1.0f;
		additionalBlendFactor = 1.0;
	}
	return self;
}

- (void)renderNode
{

	if ([currentRenderPass settings] != kMainRenderPass)
		return;

	if (!additionalBlendFactorPos)
		additionalBlendFactorPos = glGetUniformLocation(currentShader.shaderName, "additionalBlendFactor");


	const GLfloat vertices[] = {size, -size, 0, -size, -size, 0, size, size, 0, -size, size, 0};
	const GLshort texCoords[] = {0, 0, 1, 0, 0, 1, 1, 1};
	const GLubyte indices[] = {0, 2, 1, 1, 2, 3};



	myClientStateVTN(kNeedEnabled, kNeedEnabled, kNeedDisabled);
	myEnableBlendParticleCullDepthtestDepthwrite(YES, NO, YES, NO, YES);
	myBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


	glVertexAttribPointer(TEXTURE_COORD_ARRAY, 2, GL_SHORT, GL_FALSE, 0, texCoords);
	glVertexAttribPointer(VERTEX_ARRAY, 3, GL_FLOAT, GL_FALSE, 0, vertices);


	globalMaterial.color = vector4f(1.0f, 1.0f, 1.0f, 1.0f); // TODO: why not just change the color instead of the additionalblend stuff?

	[currentShader prepare];
	[texture bind];

	glUniform1f(additionalBlendFactorPos, additionalBlendFactor);


	glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, indices);



	globalInfo.drawCalls++;
	/*DRAW_CALL*/
}

- (void)dealloc
{
	[texture release];

	[super dealloc];
}
@end
