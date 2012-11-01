//
//  MacRenderViewController.m
//  Core3D
//
//  Created by CoreCode on 24.10.10.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//  Copyright (C) 2010 Apple Inc. Contains Apple Inc. Sample code
//


#import "Core3D.h"
#import "MacRenderViewController.h"


#define DEFAULT_WIDTH 800
#define DEFAULT_HEIGHT 600


@implementation DisplayLinkOpenGLView

@synthesize controller;
@synthesize openGLContext;
@synthesize hasReducedResolution;


- (CVReturn)getFrameForTime:(const CVTimeStamp *)outputTime
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFAbsoluteTime videoTime = (NSTimeInterval) outputTime->videoTime / (NSTimeInterval) outputTime->videoTimeScale;
	
	
	[controller updateForFrameTime:videoTime];
	[self drawView];
	
	
	[pool release];
	return kCVReturnSuccess;
}

static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *now, const CVTimeStamp *outputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext)
{
	CVReturn result = [(DisplayLinkOpenGLView *) displayLinkContext getFrameForTime:outputTime];
	return result;
}

- (id)initWithFrame:(NSRect)frameRect shareContext:(NSOpenGLContext *)context pixelFormat:(NSOpenGLPixelFormat *)pixelFormat
{
	
	if ((self = [super initWithFrame:frameRect]))
	{
		openGLContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:context];
		
		[[self openGLContext] makeCurrentContext];
		
		
		
		GLint swapInt = 1;
		[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
		
		CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
		CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, self);
		CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, (CGLContextObj)
														  [openGLContext CGLContextObj], (CGLPixelFormatObj)
														  [pixelFormat CGLPixelFormatObj]);
		
		
		[(NSNotificationCenter *) [NSNotificationCenter defaultCenter] addObserver:self
		                                                                  selector:@selector(reshape)
				                                                              name:NSViewGlobalFrameDidChangeNotification
					                                                        object:self];
		
#ifndef RELEASEBUILD
#ifdef TIMEDEMO
        fpsArray = [[NSMutableArray alloc] init];
		
        [self performSelector:@selector(timedemo) withObject:nil afterDelay:80.0f];
#endif
#endif
		
		if ($defaulti(@"timedemo"))
			[self performSelector:@selector(quit) withObject:nil afterDelay:80.0f];
	}
	
	return self;
}
#ifdef TIMEDEMO
- (void)timedemo
{
    int min = 999;
    int max = 0;
    float avg;
    int times = 0;
	
    for (NSNumber *n in fpsArray)
    {
        int fps = [n intValue];
        if (fps < min)
            min = fps;
		
        if (fps > max)
            max = fps;
		
        avg += fps;
        times++;
    }
	
    avg /= times;
	
    [NSCursor unhide];
    NSBeginCriticalAlertSheet(@"CoreBreach", @"Quit", nil, nil, [controller window], self, @selector(quit), @selector(quit), NULL, $stringf(@"Vendor: %s\nRenderer (%i): %s\nResolution: %@\nFPS Data min/avg/max: %i %.2f %i", glGetString(GL_VENDOR), globalInfo.gpuSuckynessClass, glGetString(GL_RENDERER), NSStringFromRect([self bounds]), min, avg, max));
	
}
#endif

- (void)quit
{
	[NSApp terminate:self];
}

- (void)setHasReducedResolution:(BOOL)_has
{
	if (_has)
	{
		hasReducedResolution = TRUE;
		NSSize fullRes = [self frame].size;
		reducedResolution = CalculateReducedResolution(fullRes);
		GLint dim[2] = {reducedResolution.width, reducedResolution.height};
		CGLSetParameter((CGLContextObj)
						[openGLContext CGLContextObj], kCGLCPSurfaceBackingSize, dim);
		CGLEnable((CGLContextObj)
				  [openGLContext CGLContextObj], kCGLCESurfaceBackingSize);
	}
}

- (void)fpsTimer
{
	globalInfo.fps = frames;
	if (globalSettings.displayFPS)
		NSLog(@"FPS: %i\tRenderedFaces: %i\n", (int) globalInfo.fps, globalInfo.renderedFaces);
	
#ifdef TIMEDEMO
    [fpsArray addObject:$numi(frames)];
#endif
	
	frames = 0;
}

- (id)initWithFrame:(NSRect)frameRect
{
	fatal("Error: DisplayLinkOpenGLView instanciated from a NIB file");
}

- (void)lockFocus
{
	[super lockFocus];
	if ([[self openGLContext] view] != self)
		[[self openGLContext] setView:self];
}

- (void)reshape
{
	// This method will be called on the main thread when resizing, but we may be drawing on a secondary thread through the display link
	// Add a mutex around to avoid the threads accessing the context simultaneously
	CGLLockContext((CGLContextObj)
				   [openGLContext CGLContextObj]);
	
	[openGLContext makeCurrentContext];
	
	
	// Delegate to the scene object to update for a change in the view size
	if (hasReducedResolution)
		[controller reshape:NSSizeToCGSize(reducedResolution)];
	else
		[controller reshape:CGSizeMake([self bounds].size.width, [self bounds].size.height)];
	
	[[self openGLContext] update];
	
	CGLUnlockContext((CGLContextObj)
					 [openGLContext CGLContextObj]);
}

- (void)drawRect:(NSRect)dirtyRect
{
	// Ignore if the display link is still running
	//if (!CVDisplayLinkIsRunning(displayLink))
	[self drawView];
}

- (void)drawView
{
	// This method will be called on both the main thread (through -drawRect:) and a secondary thread (through the display link rendering loop)
	// Also, when resizing the view, -reshape is called on the main thread, but we may be drawing on a secondary thread
	// Add a mutex around to avoid the threads accessing the context simultaneously
	CGLLockContext((CGLContextObj)
				   [openGLContext CGLContextObj]);
	
	// Make sure we draw to the right context
	[openGLContext makeCurrentContext];
	
	// Delegate to the scene object for rendering
	[controller render];
	
	[openGLContext flushBuffer];
	
	CGLUnlockContext((CGLContextObj)
					 [openGLContext CGLContextObj]);
	
	frames++;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (void)keyDown:(NSEvent *)theEvent
{
	[controller keyDown:theEvent];
}

- (void)keyUp:(NSEvent *)theEvent
{
	[controller keyUp:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[controller mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	[controller mouseUp:theEvent];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[controller mouseDown:theEvent];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	[controller mouseDown:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	[controller mouseDragged:theEvent];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	[controller scrollWheel:theEvent];
}

- (void)startAnimation
{
	if (displayLink && !CVDisplayLinkIsRunning(displayLink))
		CVDisplayLinkStart(displayLink);
	
	
	if (fpsTimer)
	{
		[fpsTimer invalidate];
		[fpsTimer release];
		fpsTimer = nil;
	}
	fpsTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(fpsTimer) userInfo:NULL repeats:YES] retain];
}

- (void)stopAnimation
{
	if (displayLink && CVDisplayLinkIsRunning(displayLink))
		CVDisplayLinkStop(displayLink);
	
	if (fpsTimer)
	{
		[fpsTimer invalidate];
		[fpsTimer release];
		fpsTimer = nil;
	}
}

- (void)dealloc
{
	//	NSLog(@"display link dealloc");
	CVDisplayLinkStop(displayLink);
	CVDisplayLinkRelease(displayLink);
	
	//	CGLDestroyContext((CGLContextObj)[openGLContext CGLContextObj]);
	[openGLContext clearDrawable];
	[openGLContext release];
	
	if (fpsTimer)
	{
		[fpsTimer invalidate];
		[fpsTimer release];
		fpsTimer = nil;
	}
#ifdef TIMEDEMO
    [fpsArray release];
#endif
	
	[(NSNotificationCenter *) [NSNotificationCenter defaultCenter] removeObserver:self
	                                                                         name:NSViewGlobalFrameDidChangeNotification
		                                                                   object:self];
	
	[super dealloc];
}

@end


@implementation KeyWindow

- (BOOL)canBecomeKeyWindow
{return YES;}
@end

RenderViewController *rvc = nil;

@implementation RenderViewController

@synthesize window, pixelFormat, isInFullScreenMode, loadingWindow;

- (id)init
{
	if ((self = [super init]))
	{
		rvc = self;

		[(NSNotificationCenter *) [NSNotificationCenter defaultCenter] addObserver:self
		                                                                  selector:@selector(willTerminate:)
				                                                              name:NSApplicationWillTerminateNotification
					                                                        object:NSApp];
	}
	return self;
}

+ (RenderViewController *)sharedController
{
	return rvc;
}

- (void)setup:(BOOL)fullscreen
{
	isInFullScreenMode = fullscreen;


	[currentView stopAnimation];


	NSRect mainDisplayRect = [[NSScreen mainScreen] frame], windowRect, viewRect;

	if (fullscreen)
	{
		windowRect = mainDisplayRect;
		viewRect = NSMakeRect(0.0, 0.0, mainDisplayRect.size.width, mainDisplayRect.size.height);
	}
	else
	{
		windowRect = NSMakeRect((mainDisplayRect.size.width - DEFAULT_WIDTH) / 2, (mainDisplayRect.size.height - DEFAULT_HEIGHT) / 2, DEFAULT_WIDTH, DEFAULT_HEIGHT);
		viewRect = NSMakeRect(0.0, 0.0, DEFAULT_WIDTH, DEFAULT_HEIGHT);
	}

	KeyWindow *newWindow = [[KeyWindow alloc] initWithContentRect:windowRect
	                                                    styleMask:(fullscreen ? NSBorderlessWindowMask : (NSTitledWindowMask | NSResizableWindowMask))
			                                              backing:NSBackingStoreBuffered
					                                        defer:YES];

	DisplayLinkOpenGLView *newView;
	if (fullscreen)
	{
		[newWindow setLevel:NSMainMenuWindowLevel + 1];
		[newWindow setHidesOnDeactivate:YES];

		if (!fullscreenView)
			fullscreenView = [[DisplayLinkOpenGLView alloc] initWithFrame:viewRect shareContext:baseContext pixelFormat:pixelFormat];

		if ($defaulti(kFullscreenResolutionFactorKey))
			[fullscreenView setHasReducedResolution:TRUE];
		newView = fullscreenView;

		[NSCursor hide];
	}
	else
	{
		if (!windowedView)
			windowedView = [[DisplayLinkOpenGLView alloc] initWithFrame:viewRect shareContext:baseContext pixelFormat:pixelFormat];

		newView = windowedView;

		[NSCursor unhide];
	}


	[window setOpaque:YES];



	if (currentView)
	{
		CGLLockContext((CGLContextObj)
		[[newView openGLContext] CGLContextObj]);
		CGLLockContext((CGLContextObj)
		[[currentView openGLContext] CGLContextObj]);

		[[newView openGLContext] copyAttributesFromContext:[currentView openGLContext] withMask:GL_ALL_ATTRIB_BITS];

		[scene resetState];

		CGLUnlockContext((CGLContextObj)
		[[newView openGLContext] CGLContextObj]);
		CGLUnlockContext((CGLContextObj)
		[[currentView openGLContext] CGLContextObj]);
	}
	if (window)
	{
		[window orderOut:self];

		[window setContentView:nil];
		[window release];
	}



	currentView = newView;
	window = newWindow;
	[window setContentView:currentView];




	// Set the scene with the full-screen viewport and viewing transformation
	if (!_scene)
	{
		_scene = [[Scene alloc] init];

		[scene reshape:CGSizeMake(viewRect.size.width, viewRect.size.height)];
		id sim = [[NSClassFromString([[NSBundle mainBundle] objectForInfoDictionaryKey:@"SimulationClass"]) alloc] init];
		if (sim)
		{
			[_scene setSimulator:sim];
			[sim release];
		}

		else
			fatal("Error: there is no valid simulation class");
	}
//	else
//		[_scene reshape:CGSizeMake(viewRect.size.width, viewRect.size.height)];




	// Assign the view's MainController to self
	[currentView setController:self];

	// Show the window
	[NSApp activateIgnoringOtherApps:YES];



	[window makeKeyAndOrderFront:self];
	[window makeFirstResponder:currentView];


	glFinish();

	if (loadingWindow)
	{
		[loadingProgress setUsesThreadedAnimation:NO];
		[loadingProgress stopAnimation:self];

		[loadingWindow close];
		loadingWindow = nil;
	}

	[currentView startAnimation];
}

- (void)setupWithPreference
{
	[self setup:$defaulti(kFullscreenKey)];
}

- (void)awakeFromNib
{
	NSInteger fsaa = $defaulti(kFsaaKey);
	NSOpenGLPixelFormatAttribute attribs[] = {
			kCGLPFAMultisample,
			kCGLPFAAccelerated,
			kCGLPFANoRecovery,
			kCGLPFADoubleBuffer,
			kCGLPFAColorSize, 24,
			kCGLPFADepthSize, 24,
			kCGLPFASampleBuffers, (fsaa > 0 ? 1 : 0),
			kCGLPFASamples, MIN((unsigned int) fsaa * 2, globalInfo.maxMultiSamples),
			0, 0, 0};

	if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
	{
		attribs[12] = kCGLPFAOpenGLProfile;
		attribs[13] = globalInfo.modernOpenGL ? kCGLOGLPVersion_3_2_Core : kCGLOGLPVersion_Legacy;
	}

	pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];

	if (!pixelFormat)
		NSLog(@"Error: No OpenGL pixel format");

	baseContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];

	[loadingWindow center];
	[loadingWindow makeKeyAndOrderFront:self];
	//[loadingWindow makeFirstResponder:view];
	[loadingProgress setUsesThreadedAnimation:YES];
	[loadingProgress startAnimation:self];
	[self performSelector:@selector(setupWithPreference) withObject:nil afterDelay:0.0];
}

- (void)willTerminate:(NSNotification *)noti
{
	//NSLog(@"will terminate not");
	[windowedView stopAnimation];
	[fullscreenView stopAnimation];
}

- (void)dealloc
{
	//NSLog(@"render view dealloc");
	[windowedView stopAnimation];
	[fullscreenView stopAnimation];

	loadingWindow = (NSWindow *) 0xbeef;
	[_scene release];

	[window orderOut:self];
	[window setContentView:nil];
	[window release];

	[(NSNotificationCenter *) [NSNotificationCenter defaultCenter] removeObserver:self
	                                                                         name:NSApplicationWillTerminateNotification
		                                                                   object:NSApp];

	//CGLDestroyContext((CGLContextObj)[baseContext CGLContextObj]);
	[baseContext clearDrawable];
	[baseContext release];
	[pixelFormat release];

	[windowedView release];
	[fullscreenView release];

	[super dealloc];
}

- (Scene *)scene
{
	return _scene;
}

- (void)render
{
	[_scene render];
}

- (void)reshape:(CGSize)size
{
	[_scene reshape:size];
}

- (void)updateForFrameTime:(CFAbsoluteTime)time
{
	[_scene update:time];
}

- (void)keyDown:(NSEvent *)theEvent
{
	if ([theEvent isARepeat])
		return;

	NSString *chars = [theEvent charactersIgnoringModifiers];

	if (![chars length])
		return;

	unichar c = [chars characterAtIndex:0];

	if ((([theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask) && (c == 'f'))
	{
		$setdefaulti(!isInFullScreenMode, kFullscreenKey);
		[self setup:!isInFullScreenMode];
	}

	@synchronized (pressedKeys)
	{
		[pressedKeys addObject:$numui([theEvent keyCode])];
		//NSLog(@" adding key %i now %@", [theEvent keyCode], [pressedKeys description]);
	}
	[[_scene simulator] keyDown:theEvent];
}

- (void)keyUp:(NSEvent *)theEvent
{
	@synchronized (pressedKeys)
	{
		[pressedKeys removeObject:$numui([theEvent keyCode])];
	}
	[[_scene simulator] keyUp:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[[_scene simulator] mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	[[_scene simulator] mouseUp:theEvent];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[[_scene simulator] mouseDown:theEvent];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	[[_scene simulator] mouseDown:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	[[_scene simulator] mouseDragged:theEvent];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	[[_scene simulator] scrollWheel:theEvent];
}
@end
