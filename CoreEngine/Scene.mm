//
//  Scene.m
//  Core3D
//
//  Created by CoreCode on 16.11.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


#import "Core3D.h"


@implementation NSString (charValue)

- (char)charValue
{return (char) [self intValue];}
@end

NSMutableArray *pressedKeys;

Material globalMaterial;
Info globalInfo;
Settings globalSettings;

Scene *scene = nil;
Camera *currentCamera = nil;
RenderPass *currentRenderPass = nil;
Shader *currentShader = nil;
Texture *currentTexture = nil;
VBO *currentVBO = nil;

@implementation Scene

@synthesize objects, simulator, mainRenderPass, renderpasses, bounds, colorOnlyShader, textureOnlyShader, phongTextureShader, phongOnlyShader;


- (id)init
{
	if ((self = [super init]))
	{
		if (scene != nil)
			fatal("Error: cannot initialize the scene twice");

		scene = self;

		pressedKeys = [[NSMutableArray alloc] initWithCapacity:5];

		globalInfo.frame = 0;
		globalMaterial.lightModelAmbient = vector4f(0.2f, 0.2f, 0.2f, 1.0f);

#ifdef DEBUG
//        NSString *extensionString = [NSString stringWithUTF8String:(char *)glGetString(GL_EXTENSIONS)]; // warning: not GL3 compliant
//        NSArray *extensions = [extensionString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//        for (NSString *oneExtension in extensions)
//            NSLog(oneExtension);


		NSArray *tex = [Texture allTextures];
		if (tex && [tex count])
		{
			for (Texture *t in tex)
				NSLog(@"Error: leftover texture %@ (%i)", [t name], [t texName]);

			fatal("Error: textures leftover");
		}
		NSArray *sha = [Shader allShaders];
		if (sha && [sha count])
		{
			for (NSArray *t in sha)
			{
				if ([t count])
					fatal("Error: shaders leftover %s", [[t description] UTF8String]);
			}
		}
#ifndef DISABLE_SOUND
		NSArray *snd = [SoundBuffer allBuffers];
		if (snd && [snd count])
		{
			for (SoundBuffer *t in snd)
				NSLog(@"Error: leftover sndbuffer %@", [t name]);

			fatal("Error: leftover sndbuffer");
		}
#endif
#endif


		globalSettings.displayFPS = IS_TIMEDEMO || $defaulti(@"displayfps");
		if (globalSettings.displayFPS)
			NSLog(@"Warning: hidden settings activated: displayfps %i timedemo %i", globalSettings.displayFPS, (int) $defaulti(@"timedemo"));

		globalSettings.slowMotion = kNoSlowmo;
		globalSettings.shadowFiltering = (shadowFilteringEnum) $defaulti(kShadowFilteringKey);
		globalSettings.shadowSize = $defaulti(kShadowSizeKey);
		globalSettings.outlineMode = $defaulti(kOutlinesKey);

#if !defined(__COCOTRON__) && !defined(TARGET_OS_IPHONE)
        NSData *cd = $default(kOutlinesColorKey);
        if (cd)
        {
            NSColor *value = [NSUnarchiver unarchiveObjectWithData:cd];
#if defined(GNUSTEP_BASE_MAJOR_VERSION) &&  defined(GNUSTEP_BASE_MINOR_VERSION) && \
( GNUSTEP_BASE_MAJOR_VERSION < 1 || \
(GNUSTEP_BASE_MAJOR_VERSION == 1 && \
GNUSTEP_BASE_MINOR_VERSION < 24))
			float c[4];
#else
			CGFloat c[4];
#endif            
            [value getComponents:c];
            globalSettings.outlineColor = vector4f(c[0], c[1], c[2], 1.0);
        }
#else
		globalSettings.outlineColor = vector4f(0.0f, 0.0f, 0.0f, 1.0f);
#endif
		if (!$defaulti(kShadowsEnabledKey))
			globalSettings.shadowMode = kNoShadow;
		else
			globalSettings.shadowMode = kShipOnly;

#if !defined(DISABLE_SOUND) && !defined(TIMEDEMO)

		globalSettings.soundEnabled = $defaulti(kSoundEnabledKey);
		globalSettings.soundVolume = $defaultf(kSoundVolumeKey);
#endif
//		globalSettings.shadowMode = (shadowModeEnum) 0;

		setlocale(LC_NUMERIC, "C");
		std::srand((unsigned) time(NULL));
#ifndef __APPLE__
		init_opengl_function_pointers();
#endif
		NanosecondsInit();

		ResetState();

		objects = (MutableSceneNodeArray *) [[NSMutableArray alloc] initWithCapacity:100];
		renderpasses = (MutableRenderPassArray *) [[NSMutableArray alloc] initWithCapacity:5];
		_renderTargets = [[NSMutableArray alloc] initWithCapacity:5];



		if ([self respondsToSelector:@selector(initSound)])
			[self performSelector:@selector(initSound)];


		textureOnlyShader = [Shader newShaderNamed:@"texture" withTexcoordsBound:YES andNormalsBound:NO];
		colorOnlyShader = [Shader newShaderNamed:@"color" withTexcoordsBound:NO andNormalsBound:NO];
		phongTextureShader = [Shader newShaderNamed:@"phong" withDefines:@"#define TEXTURE 1\n" withTexcoordsBound:YES andNormalsBound:YES];
		phongOnlyShader = [Shader newShaderNamed:@"phong" withTexcoordsBound:NO andNormalsBound:YES];
	}
	return scene;
}

- (void)resetState
{
	ResetState();
	currentShader = nil;
	currentTexture = nil;
	currentVBO = nil;

	for (RenderPass *r in renderpasses)
	{
		NSArray *allObjects = [r newListOfAllObjects];

		for (SceneNode *sn in allObjects)
			if ([sn respondsToSelector:@selector(resetState)])
				[sn performSelector:@selector(resetState)];

		[allObjects release];
	}

	for (SceneNode *sn in objects)
		if ([sn respondsToSelector:@selector(resetState)])
			[sn performSelector:@selector(resetState)];
}

- (void)removeNode:(SceneNode *)node
{
	[objects removeObject:node];

	for (SceneNode *n in objects)
		[n removeNode:node];
	
	for (RenderPass *rp in renderpasses)
	{
		[[rp objects] removeObject:node];
		
		for (SceneNode *n in [rp objects])
			[n removeNode:node];
	}
}

- (void)reshape:(CGSize)size
{
//	NSLog(@"reshape %f %f THREAD: %@", size.width, size.height, [NSThread currentThread]);

	bounds = size;

	for (NSValue *rtv in _renderTargets)
		[(RenderTarget *) [rtv pointerValue] reshape:size];

	for (RenderPass *rp in renderpasses)
		[rp reshape:size];

	for (SceneNode *obj in objects)
		[obj reshape:size];
}

- (void)processKeys
{
#ifndef TARGET_OS_IPHONE
#ifndef RELEASEBUILD
	@synchronized(pressedKeys)
	{
		NSNumber *keyToErase = nil;
		for (NSNumber *keyHit in pressedKeys)
		{
			keyToErase = keyHit;
			switch ([keyHit intValue])
			{
				case kVK_F1:
					globalSettings.displayFPS = !globalSettings.displayFPS;
					break;
				case kVK_F2:
					globalSettings.doWireframe = !globalSettings.doWireframe;
					NSLog(@"%@",  globalSettings.doWireframe ? @"Wireframe ON" : @"Wireframe OFF");
					break;
				case kVK_F3:
					globalSettings.disableCulling = !globalSettings.disableCulling;
					NSLog(@"%@", globalSettings.disableCulling ? @"CULLING OFF" : @"CULLING ON");
					break;
				case kVK_F4:
					globalSettings.disableTex = !globalSettings.disableTex;
                        NSLog(@"%@",  globalSettings.disableTex ? @"TEX OFF" : @"TEX ON");
					break;
				case kVK_F5:
                    if (globalSettings.slowMotion == kNoSlowmo)
                        globalSettings.slowMotion = kWeaponSlowmo;
                    else
                        globalSettings.slowMotion = kNoSlowmo;
                    NSLog(@"%@", globalSettings.slowMotion ? @"SLOWMO O" : @"SLOWMO OFF");
					break;
				default:
					keyToErase = nil;
					break;
			}
		}
#ifdef __COCOTRON__
		if (keyToErase)	[pressedKeys removeObject:$numui([keyToErase unsignedIntValue])];
#else
        if (keyToErase)	[pressedKeys removeObject:keyToErase];
#endif
	}
#endif
#endif
}

- (void)update:(CFAbsoluteTime)time
{
//	NSLog(@"update THREAD: %@", [NSThread currentThread]);
	static CFAbsoluteTime firstFrame = 0.0;
	static CFAbsoluteTime lastFrameTime = 0.0;

#ifndef RELEASEBUILD
	uint64_t micro = GetNanoseconds() / 1000;
#endif

	if (globalInfo.frame == 0)
	{
		firstFrame = time;
		lastFrameTime = 0.0;
		globalInfo.frameDiff = 0.0;
		//[self reshape:CGSizeMake(800, 600)]; // TODO: REMOVE
	}
	else
	{
		CFAbsoluteTime newFrameTime = time - firstFrame;

		globalInfo.frameDiff = min(newFrameTime - lastFrameTime, 0.3);
		if (globalSettings.slowMotion == kWeaponSlowmo)
			globalInfo.frameDiff /= 10.0f;
		else if (globalSettings.slowMotion == kNitroSlowmo)
			globalInfo.frameDiff /= 3.3f;

		lastFrameTime = newFrameTime;
	}
	globalInfo.frame++;

	//NSLog(@"frame %lu time %f diff %f start %f", (unsigned long)globalInfo.frame, time, globalInfo.frameDiff, firstFrame);
	[self processKeys];

	if ([simulator paused])
		return;

	[simulator update];


	for (SceneNode *obj in objects)
		[obj update];

#ifndef RELEASEBUILD
	uint64_t post = GetNanoseconds() / 1000;
	float frameTime = (post - micro) / 1000.0f;
	if (frameTime > 3.0f)
	{
		NSLog(@"updating frame %lu took %f", (unsigned long) globalInfo.frame, frameTime);
	}
#endif
}

- (void)render
{
#if defined(TARGET_OS_MAC)
    if (globalInfo.frame % (60 * 60 * 3) == 0)
        UpdateSystemActivity(1);
#endif

	globalInfo.renderedFaces = globalInfo.visitedNodes = globalInfo.drawCalls = 0;
//	NSLog(@"render THREAD: %@  frame %lu", [NSThread currentThread], globalInfo.frame);


#if !defined(RELEASEBUILD) && !defined(TARGET_OS_IPHONE)
	 uint64_t micro = GetNanoseconds() / 1000;
#endif


	for (RenderPass *rp in renderpasses)
	{
		currentCamera = [rp camera];
		currentRenderPass = rp;
		[rp render];
	}

	[simulator render];

	currentCamera = nil;
	currentRenderPass = nil;



#if !defined(RELEASEBUILD) && !defined(TARGET_OS_IPHONE)
	uint64_t post = GetNanoseconds() / 1000;
    float frameTime = (post-micro) / 1000.0f;
    if (frameTime > 16.0f)
        NSLog(@"Info: rendering frame %lu took %f", (unsigned long)globalInfo.frame, frameTime);
#endif

//	NSLog(@"render THREAD: %@			DONE", [NSThread currentThread]);
//    if (globalInfo.frame % 30 == 0)
//        NSLog(@"renderedFaces %i", globalInfo.renderedFaces);


#ifdef SDL
    BOOL screenshot = NO;
	NSNumber *keyToErase = nil;
	for (NSNumber *keyHit in pressedKeys)
	{
		keyToErase = keyHit;
		switch ([keyHit intValue])
		{
			case kVK_F1:
                screenshot = YES;
				break;
			default:
				keyToErase = nil;
				break;
		}
	}
#ifdef __COCOTRON__
	if (keyToErase)	[pressedKeys removeObject:$numui([keyToErase unsignedIntValue])];
#else
	if (keyToErase)	[pressedKeys removeObject:keyToErase];
#endif
    
    if (screenshot)
    {
        uint8_t *screenShotBuffer;
        screenShotBuffer = (uint8_t *) calloc(bounds.width * bounds.height, 4);
        glReadPixels(0, 0, bounds.width, bounds.height, GL_RGBA, GL_UNSIGNED_BYTE, screenShotBuffer);
        NSString *timeString = [[NSDate date] descriptionWithCalendarFormat:@"%Y-%m-%d_%H-%M-%S" timeZone:nil locale:nil];

        SavePixelsToTGAFile(screenShotBuffer, bounds, [$stringf(@"~/CoreBreach-Screenshot-%@-%i.tiff", timeString, globalInfo.frame) stringByExpandingTildeInPath]);
        
        free(screenShotBuffer);
    }
#endif

	glError()
}

- (void)dealloc
{
	DeleteState();

	//NSLog(@"scene dealloc");
	[colorOnlyShader release];
	[textureOnlyShader release];
	[phongOnlyShader release];
	[phongTextureShader release];

	[pressedKeys release];
	[self setSimulator:nil];
	[self setMainRenderPass:nil];

	[renderpasses release];
	[objects release];
	[_renderTargets release];

	if ([self respondsToSelector:@selector(deallocSound)])
		[self performSelector:@selector(deallocSound)];

	scene = nil;
	[super dealloc];
}

- (void)addRenderTarget:(RenderTarget *)rt
{
	[_renderTargets addObject:[NSValue valueWithPointer:rt]];
}

- (void)removeRenderTarget:(RenderTarget *)rt
{
	for (NSUInteger i = 0; i < [_renderTargets count]; i++)
	{
		if ([[_renderTargets objectAtIndex:i] pointerValue] == rt)
		{
			[_renderTargets removeObjectAtIndex:i];
			break;
		}
	}
}
@end

@implementation Scene (TGFExport)

- (void)_recursiveInfo:(NSMutableString *)info forObject:(SceneNode *)o counterIndex:(int *)index withFather:(int)father printConnection:(BOOL)printConnection
{
	int i = ++(*index);

	if (printConnection) [info appendFormat:@"%i %i\n", father, i];
	else [info appendFormat:@"%i %@:%@\n", i, [[o class] description], [o name]];

	for (SceneNode *obj in [o children])
		[self _recursiveInfo:info forObject:obj counterIndex:index withFather:i printConnection:printConnection];
}

- (void)printSceneGraphAsTGF
{
	NSMutableString *nodes = [NSMutableString string], *edges = [NSMutableString string];
	int i = 1, v = 1;

	for (SceneNode *obj in objects)
	{
		[self _recursiveInfo:nodes forObject:obj counterIndex:&i withFather:1 printConnection:NO];
		[self _recursiveInfo:edges forObject:obj counterIndex:&v withFather:1 printConnection:YES];
	}

	NSLog(@"1 Scene\n%@#\n%@", nodes, edges);
}
@end
