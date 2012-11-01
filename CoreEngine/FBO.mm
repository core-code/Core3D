//
//  FBO.m
//  Core3D
//
//  Created by CoreCode on 20.11.10.
//  Copyright 2010 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#import "Core3D.h"
#import "FBO.h"


@implementation FBO


@synthesize disableDepthTexture;
@synthesize disableColorTexture;
@synthesize colorTexture, depthTexture;

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (void)initTextures
{
	depthTexture = [[Texture alloc] init];
	colorTexture = [[Texture alloc] init];


	[colorTexture setMinFilter:GL_NEAREST];
	[colorTexture setMagFilter:GL_NEAREST];
#ifdef GL_ES_VERSION_2_0
	[colorTexture setInternalFormat:GL_RGBA];
#else
	[colorTexture setInternalFormat:GL_RGBA8];
#endif
	[colorTexture setFormat:GL_RGBA];
	[colorTexture setWrapS:GL_CLAMP_TO_EDGE];
	[colorTexture setWrapT:GL_CLAMP_TO_EDGE];
#ifdef GL_ES_VERSION_2_0
	[colorTexture setType:GL_UNSIGNED_SHORT_4_4_4_4];
#else
	[colorTexture setType:GL_UNSIGNED_BYTE];
#endif


	[depthTexture setMinFilter:GL_NEAREST];
	[depthTexture setMagFilter:GL_NEAREST];
	[depthTexture setInternalFormat:GL_DEPTH_COMPONENT24];
	[depthTexture setFormat:GL_DEPTH_COMPONENT];
	[depthTexture setWrapS:GL_CLAMP_TO_EDGE];
	[depthTexture setWrapT:GL_CLAMP_TO_EDGE];
#ifdef GL_ES_VERSION_2_0
	[depthTexture setType:GL_UNSIGNED_SHORT];
#else
	[depthTexture setType:GL_UNSIGNED_BYTE];
#endif
}

- (id)initWithFixedWidth:(float)_width andFixedHeight:(float)_height
{
	if ((self = [super initWithFixedWidth:_width andFixedHeight:_height]))
	{
		[self initTextures];

		glGenFramebuffers(1, &fbo);
	}
	return self;
}

- (id)initWithWidthMultiplier:(float)_widthMultiplier andHeightMultiplier:(float)_heightMultiplier
{
	if ((self = [super initWithWidthMultiplier:_widthMultiplier andHeightMultiplier:_heightMultiplier]))
	{
		[self initTextures];

		glGenFramebuffers(1, &fbo);
	}
	return self;
}

- (void)dealloc
{
	glDeleteFramebuffers(1, &fbo);
	fbo = 0;

	[colorTexture release];
	[depthTexture release];

	[super dealloc];
}

- (void)reshape:(CGSize)size
{
	if ((!disableColorTexture && !colorTexture) || (!disableDepthTexture && !depthTexture))
		fatal("FBO has not been loaded");

	if (fixedSize)
		return;


	[super reshape:size];

	[self load];
}

- (void)load
{
	if (disableColorTexture)
	{
		[colorTexture release];
		colorTexture = nil;
	}
	if (disableDepthTexture)
	{
		[depthTexture release];
		depthTexture = nil;
	}


	[colorTexture setWidth:(size_t) bounds.width];
	[colorTexture setHeight:(size_t) bounds.height];
	[colorTexture load];


	[depthTexture setWidth:(size_t) bounds.width];
	[depthTexture setHeight:(size_t) bounds.height];
	[depthTexture load];


#ifndef TARGET_OS_IPHONE
    [self bind];

 // #warning re-evaulate FBO disabling

    if (!disableColorTexture)
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, [colorTexture texName], 0);
    else
    {
#ifndef GL_ES_VERSION_2_0
        glDrawBuffer(GL_NONE);
        glReadBuffer(GL_NONE);
#else
        printf("Warning: fixme?");
#endif
    }

#ifdef TARGET_OS_IPHONE
    GLuint					_depthBuffer, oldRenderbuffer;
    glGetIntegerv(GL_RENDERBUFFER_BINDING, (GLint *) &oldRenderbuffer);
    glGenRenderbuffers(1, &_depthBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, bounds.width, bounds.height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, oldRenderbuffer);
#else
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, [depthTexture texName], 0);
#endif

    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        fatal("Error: couldn't setup FBO %04x", (unsigned int)glCheckFramebufferStatus(GL_FRAMEBUFFER));

    [self unbind];
#endif
}

- (void)bind
{
#ifndef TARGET_OS_IPHONE
	glBindFramebuffer(GL_FRAMEBUFFER, fbo);
#endif
}

- (void)unbind
{
#ifndef TARGET_OS_IPHONE
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
#endif
}
@end
