//
//  Particlesystem.m
//  Core3D
//
//  Created by CoreCode on 03.06.08.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


#import "Core3D.h"
#import "Particlesystem.h"


@implementation Particlesystem

@synthesize size, intensity, basePointSize, srcBlend, dstBlend, dontDepthtest, blendColor;

- (void)initOptions
{}

- (id)initWithParticleCount:(int)_particleCount andTextureNamed:(NSString *)_texture
{
	if ((self = [super init]))
	{
		particleCount = _particleCount;

		basePointSize = 0.0f;
		pointSize = 0.0f;
		intensity = 1.0f;
		size = 1.0f;

		pointsprite = [Texture newTextureNamed:_texture];
		[pointsprite load];


		[self initOptions];

		NSMutableString *defines = [NSMutableString string];

		if (pointSize > 0.0) [defines appendString:@"#define SCALE_PARTICLES\n"];
		if ((pointSize > 0.0) && (maxSize > 0.0)) [defines appendString:@"#define MAX_SIZE\n"];
		if ((pointSize > 0.0) && (minSize > 0.0)) [defines appendString:@"#define MIN_SIZE\n"];

		shader = [Shader newShaderNamed:@"pointsprite" withDefines:defines withTexcoordsBound:NO andNormalsBound:NO];

		[shader bind];
		glUniform1i(glGetUniformLocation(shader.shaderName, "pointspriteTexture"), 0);
		glUniform1f(glGetUniformLocation(shader.shaderName, "pointSize"), pointSize);
		glUniform1f(glGetUniformLocation(shader.shaderName, "minSize"), minSize);
		glUniform1f(glGetUniformLocation(shader.shaderName, "maxSize"), maxSize);



		positions = (float *) malloc(particleCount * sizeof(float) * 3);
		velocities = (float *) malloc(particleCount * sizeof(float) * 3);

//        srcBlend = GL_SRC_ALPHA;
//        dstBlend = GL_ONE_MINUS_SRC_ALPHA;

		srcBlend = GL_SRC_ALPHA;
		dstBlend = GL_CONSTANT_COLOR;

		blendColor = vector4f(0.99, 0.94, 0.97, 0.4);

		[self initParticles];
	}

	return self;
}

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (void)initParticles
{[self doesNotRecognizeSelector:_cmd];}

- (void)updateParticles
{[self doesNotRecognizeSelector:_cmd];}

//- (void)updateNode
//{
////    if (visible)
//    
//    [super updateNode];
//}

- (void)renderNode
{
	if (currentRenderPass.settings != kMainRenderPass || size < 0.01)
		return;

	//#ifdef VFC_PARTICLE_SYSTEM

	GLfloat frustum[6][4];

	extract_frustum_planes([currentCamera modelViewMatrix],
			[currentCamera projectionMatrix],
			frustum, cml::z_clip_neg_one, false);

	if ((AABBExtent[0] != FLT_MAX) && AABoxInFrustum((const float ( *)[4]) frustum, AABBOrigin[0], AABBOrigin[1], AABBOrigin[2], AABBExtent[0], AABBExtent[1], AABBExtent[2]) == kOutside)
		return;
	//#endif

	if (![[scene simulator] paused])
		[self updateParticles];


	myEnableBlendParticleCullDepthtestDepthwrite(YES, YES, NO, !dontDepthtest, NO);
	myBlendColor(blendColor[0], blendColor[1], blendColor[2], blendColor[3]);
	myBlendFunc(srcBlend, dstBlend);
	myClientStateVTN(kNeedEnabled, kNeedDisabled, kNeedDisabled);

	assert(shader);

	[shader bind];
	[pointsprite bind];



	glVertexAttribPointer(VERTEX_ARRAY, 3, GL_FLOAT, GL_FALSE, 0, positions);

	[currentShader prepare];


	if (basePointSize > 0.01)
		[currentShader setUniformf:pointSize forKey:@"pointSize"];


	[currentShader setUniformf:size forKey:@"size"];
	[currentShader setUniformf:intensity forKey:@"intensity"];



	glDrawArrays(GL_POINTS, 0, particleCount);
	globalInfo.drawCalls++;
	/*DRAW_CALL*/
}

- (void)dealloc
{
	free(positions);
	free(velocities);

	[pointsprite release];

	[shader release];

	[super dealloc];
}
@end
