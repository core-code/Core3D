//
//  RenderPass.m
//  Core3D
//
//  Created by CoreCode on 21.11.10.
//  Copyright 2010 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#import "Core3D.h"
#import "RenderPass.h"
#import "ShadowShader.h"
#import "FocusingCamera.h"


#undef glEnable
#undef glDisable

@implementation RenderPass

@synthesize camera, lights, objects, renderTarget, autoresizingMask, frame, settings, viewportMatrix, currentPVSCell;

+ (RenderPass *)mainRenderPass
{
	RenderPass *rp = [[[RenderPass alloc] initWithFrame:CGRectMake(0, 0, [scene bounds].width, [scene bounds].height)
	                                andAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable] autorelease];
	[rp setRenderTarget:[[[RenderTarget alloc] initWithWidthMultiplier:1.0 andHeightMultiplier:1.0] autorelease]];

	Light *light = [[[Light alloc] init] autorelease];
	[[rp lights] addObject:light];

	[scene setMainRenderPass:rp];
	[[scene renderpasses] addObject:rp];

	return rp;
}

+ (RenderPass *)shadowRenderPassWithSize:(int)size light:(Light *)light casters:(NSArray *)casters andMainCamera:(Camera *)mainCamera
{
	ShadowShader *ss = [[ShadowShader alloc] init];
	[[ss children] addObjectsFromArray:casters];

	RenderPass *sp = [[RenderPass alloc] initWithFrame:CGRectMake(0, 0, size, size) andAutoresizingMask:0];
	sp.settings = kRenderPassUpdateCulling;
	FocusingCamera *fc = [[FocusingCamera alloc] init];
	[sp setCamera:fc];
	[fc release];
//	[(FocusingCamera *)[sp camera] setMainCamera:mainCamera];
	[[sp camera] setAxisConfiguration:kXYZRotation];
	[[sp camera] setPosition:vector3f(0, 0, 0)];
	[[sp camera] setRelativeModeTarget:light];
	[[sp objects] addObject:ss];
	[ss release];

	FBO *fbo = [[FBO alloc] initWithFixedWidth:size andFixedHeight:size];
	[fbo setDisableColorTexture:YES];
	[[fbo depthTexture] setWrapS:GL_CLAMP_TO_EDGE];
	[[fbo depthTexture] setWrapT:GL_CLAMP_TO_EDGE];
#ifdef GL_ES_VERSION_2_0
	[[fbo depthTexture] setFormat:GL_DEPTH_COMPONENT];
	[[fbo depthTexture] setInternalFormat:GL_DEPTH_COMPONENT];
	[[fbo depthTexture] setType:GL_UNSIGNED_SHORT];
#else
	[[fbo depthTexture] setType:GL_FLOAT];
	//[[fbo depthTexture] setDepthTextureMode:GL_INTENSITY];
	[[fbo depthTexture] setCompareMode:GL_COMPARE_R_TO_TEXTURE];
#endif
	if (globalSettings.shadowFiltering >= kPCFHardware && globalSettings.shadowFiltering <= kPCF16)
	{
		[[fbo depthTexture] setMinFilter:GL_LINEAR];
		[[fbo depthTexture] setMagFilter:GL_LINEAR];
	}
	else
	{
		[[fbo depthTexture] setMinFilter:GL_NEAREST];
		[[fbo depthTexture] setMagFilter:GL_NEAREST];
	}
	[[fbo depthTexture] setCompareFunc:GL_LEQUAL];
	//	[[fbo depthTexture] setInternalFormat:GL_DEPTH_COMPONENT32F];
	//[[fbo depthTexture] setInternalFormat:GL_DEPTH_COMPONENT24];
	[fbo load];
	[sp setRenderTarget:fbo];
	[fbo release];

	assert([[fbo depthTexture] permanentlyBind]);

	return [sp autorelease];
}

- (id)init
{
	return [self initWithFrame:CGRectMake(0, 0, [scene bounds].width, [scene bounds].height)
		   andAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
}

- (id)initWithFrame:(CGRect)_frame andAutoresizingMask:(int)_mask
{
	if ((self = [super init]))
	{
		frame = _frame;
		autoresizingMask = _mask;
		settings = kMainRenderPass;
		lights = (MutableLightArray *) [[NSMutableArray alloc] initWithCapacity:10];
		objects = (MutableSceneNodeArray *) [[NSMutableArray alloc] initWithCapacity:10];
		camera = [[Camera alloc] init];
		currentPVSCell = -1;
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithString:$stringf(@"<RenderPass: %p lights %li objects %li frame %f %f %f %f rendertarge %@>", self, [lights count], [objects count], frame.origin.x, frame.origin.y, frame.size.width, frame.size.height, [renderTarget description])];
}

- (void)dealloc
{
	[lights release];
	[objects release];
	[camera release];
	[renderTarget release];

	[super dealloc];
}

- (void)resizeWithOldSuperviewSize:(CGSize)oldSize andNewSuperviewSize:(CGSize)newSize // from cocotron Copyright (c) 2006-2007 Christopher J. W. Lloyd
{
	CGRect _frame = [self frame];
	BOOL originChanged = NO, sizeChanged = NO;

	if (autoresizingMask & kCALayerMinXMargin)
	{
		if (autoresizingMask & kCALayerWidthSizable)
		{
			if (autoresizingMask & kCALayerMaxXMargin)
			{
				_frame.origin.x += ((newSize.width - oldSize.width) / 3);
				_frame.size.width += ((newSize.width - oldSize.width) / 3);
			}
			else
			{
				_frame.origin.x += ((newSize.width - oldSize.width) / 2);
				_frame.size.width += ((newSize.width - oldSize.width) / 2);
			}
			originChanged = YES;
			sizeChanged = YES;
		}
		else if (autoresizingMask & kCALayerMaxXMargin)
		{
			_frame.origin.x += ((newSize.width - oldSize.width) / 2);
			originChanged = YES;
		}
		else
		{
			_frame.origin.x += newSize.width - oldSize.width;
			originChanged = YES;
		}
	}
	else if (autoresizingMask & kCALayerWidthSizable)
	{
		if (autoresizingMask & kCALayerMaxXMargin)
			_frame.size.width += ((newSize.width - oldSize.width) / 2);
		else
			_frame.size.width += newSize.width - oldSize.width;
		sizeChanged = YES;
	}
	else if (autoresizingMask & kCALayerMaxXMargin)
	{
		// don't move or resize
	}


	if (autoresizingMask & kCALayerMinYMargin)
	{
		if (autoresizingMask & kCALayerHeightSizable)
		{
			if (autoresizingMask & kCALayerMaxYMargin)
			{
				_frame.origin.y += ((newSize.height - oldSize.height) / 3);
				_frame.size.height += ((newSize.height - oldSize.height) / 3);
			}
			else
			{
				_frame.origin.y += ((newSize.height - oldSize.height) / 2);
				_frame.size.height += ((newSize.height - oldSize.height) / 2);
			}
			originChanged = YES;
			sizeChanged = YES;
		}
		else if (autoresizingMask & kCALayerMaxYMargin)
		{
			_frame.origin.y += ((newSize.height - oldSize.height) / 2);
			originChanged = YES;
		}
		else
		{
			_frame.origin.y += newSize.height - oldSize.height;
			originChanged = YES;
		}
	}
	else if (autoresizingMask & kCALayerHeightSizable)
	{
		if (autoresizingMask & kCALayerMaxYMargin)
			_frame.size.height += ((newSize.height - oldSize.height) / 2);
		else
			_frame.size.height += newSize.height - oldSize.height;
		sizeChanged = YES;
	}

	if (originChanged || sizeChanged)
		[self setFrame:_frame];
}

- (void)setCamera:(Camera *)newCamera
{
	if (newCamera != camera)
	{
		[camera release];
		camera = newCamera;
		[camera retain];
		[camera reshape:frame.size];
	}
}

- (void)reshape:(CGSize)size
{
//	NSLog(@"RenderPass reshape input %@ old %@ ", NSStringFromSize(NSSizeFromCGSize(size)), NSStringFromRect(NSRectFromCGRect(frame)));

	[self resizeWithOldSuperviewSize:[renderTarget previousBounds] andNewSuperviewSize:[renderTarget bounds]];

	[camera reshape:frame.size];

//	NSLog(@"RenderPass reshape new %@ ", NSStringFromRect(NSRectFromCGRect(frame)));
}

- (NSArray *)newListOfAllObjects
{
	NSMutableArray *_children;
#ifdef GNUSTEP
    _children = [[NSMutableArray alloc] init];
#else
	_children = (NSMutableArray *) CFArrayCreateMutable(kCFAllocatorDefault, 5, NULL);
#endif

	for (SceneNode *sn in objects)
	{
		[_children addObject:sn];

		NSArray *grandChildren = [sn allocListOfAllChildren];
		[_children addObjectsFromArray:grandChildren];
		[grandChildren release];
	}

	return _children;
}

- (void)render
{
	if (!renderTarget)
		NSLog(@"Warning: no render target set!");

	[renderTarget bind];


	cml::matrix_viewport(viewportMatrix, (double) frame.origin.x, (double) frame.origin.x + (double) frame.size.width, (double) frame.origin.y, (double) frame.origin.y + (double) frame.size.height, cml::z_clip_neg_one);

	myViewport((GLint) frame.origin.x, (GLint) frame.origin.y, (GLsizei) frame.size.width, (GLsizei) frame.size.height);
#ifndef TARGET_OS_IPHONE
	glEnable(GL_SCISSOR_TEST);
	glScissor((GLint)frame.origin.x, (GLint)frame.origin.y, (GLsizei)frame.size.width, (GLsizei)frame.size.height);
#endif
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
#ifndef TARGET_OS_IPHONE
    glDisable(GL_SCISSOR_TEST);
#endif

	[camera identity];


	[camera transform];


	[objects makeObjectsPerformSelector:@selector(render)];

	[renderTarget unbind];
}
@end
