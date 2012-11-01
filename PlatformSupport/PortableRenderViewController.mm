//
//  PortableRenderViewController.mm
//  Core3D
//
//  Created by CoreCode on 24.10.10.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see _MIT_LICENSE.txt
//  Copyright (C) 2010 Apple Inc. Contains Apple Inc. Sample code
//


#import "Core3D.h"
#import "PortableRenderViewController.h"

@implementation PortableOpenGLView
@synthesize controller;

- (void)start
{
#ifdef __APPLE__
	ProcessSerialNumber psn;
	GetCurrentProcess(&psn);
	SetFrontProcess(&psn);
#endif

	timer = [NSTimer timerWithTimeInterval:(1.0f/60.0f) target:self selector:@selector(animationTimer:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode]; // ensure timer fires during resize

	pressedKeys = [[NSMutableArray alloc] initWithCapacity:5];
	
	startDate = [[NSDate date] retain];

	[[self window] zoom:self];
}

- (void)animationTimer:(NSTimer *)timer
{
	//[self drawRect:[self bounds]]; // redraw now instead dirty to enable updates during live resize
	[self setNeedsDisplay:YES];
}

- (void)prepareOpenGL
{
#ifndef GNUSTEP
	const GLint swap = !globalSettings.disableVBLSync;
	CGLSetParameter(CGLGetCurrentContext(), kCGLCPSwapInterval, &swap);
#endif
	
	[controller prepareOpenGL];
}

- (void)reshape
{
#ifndef __COCOTRON__
	[[self openGLContext] update];
#endif
	[controller reshape:CGSizeMake([self bounds].size.width, [self bounds].size.height)];
}

- (void)drawRect:(NSRect)rect
{
	double time = (double)[[NSDate date] timeIntervalSinceDate:startDate];
	[controller updateForFrameTime:time];
	[controller render];

	[[self openGLContext] flushBuffer];
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
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
@end

RenderViewController *rvc = nil;

@implementation RenderViewController

@synthesize window, pixelFormat;

- (id)init
{
	if ((self = [super init]))
	{
		rvc = self;

		[(NSNotificationCenter *)[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(willTerminate)
													 name:NSApplicationWillTerminateNotification
												   object:NSApp];
	}
	return self;
}

+ (id)sharedController
{
	return rvc;
}

- (void)setup:(BOOL)fullscreen
{

	NSRect mainDisplayRect = [[NSScreen mainScreen] frame], windowRect, viewRect;

	{
		windowRect = NSMakeRect((mainDisplayRect.size.width - 1024) / 2, (mainDisplayRect.size.height - 768) / 2, 1024, 768);
		viewRect = NSMakeRect(0.0, 0.0, 1024, 768);
	}

	window = [[NSWindow alloc] initWithContentRect:windowRect
										 styleMask:NSTitledWindowMask | NSResizableWindowMask
										   backing:NSBackingStoreBuffered
											 defer:YES];

	view = [[PortableOpenGLView alloc] initWithFrame:viewRect pixelFormat:pixelFormat];
	[view start];




	[window setContentView:view];
	// Assign the view's MainController to self
	[view setController:self];

	// Show the window
	[NSApp activateIgnoringOtherApps:YES];
	[window makeKeyAndOrderFront:self];
	[window makeFirstResponder:view];
}

- (void)prepareOpenGL
{
	
	// Set the scene with the full-screen viewport and viewing transformation
	if (!_scene)
	{
		_scene = [[Scene alloc] init];
		
		//	[scene reshape:CGSizeMake(viewRect.size.width, viewRect.size.height)];
		
        id sim = [[NSClassFromString([[NSBundle mainBundle] objectForInfoDictionaryKey:@"SimulationClass"]) alloc] init];
		if (sim)
		{


			[_scene setSimulator:sim];
			[sim release];
			[loadingWindow close];
		}
		
		else
			fatal("Error: there is no valid simulation class");
	}
	//	else
	//		[_scene reshape:CGSizeMake(viewRect.size.width, viewRect.size.height)];
}

- (void)awakeFromNib
{
	NSUInteger fsaa = $defaulti(kFsaaKey);

	NSOpenGLPixelFormatAttribute attribs[] = {
		NSOpenGLPFAAccelerated,
		NSOpenGLPFANoRecovery,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAColorSize, (NSOpenGLPixelFormatAttribute) 24,
		NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute) 24,
		NSOpenGLPFASampleBuffers, (NSOpenGLPixelFormatAttribute) (fsaa > 0 ? 1 : 0),
		NSOpenGLPFASamples, (NSOpenGLPixelFormatAttribute) (fsaa * 2),
		(NSOpenGLPixelFormatAttribute) 0 };
	pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];

    if (!pixelFormat)
		NSLog(@"No OpenGL pixel format");

	[loadingWindow center];
	[loadingWindow makeKeyAndOrderFront:self];
	//[loadingWindow makeFirstResponder:view];
	[loadingProgress setUsesThreadedAnimation:YES];
	[loadingProgress startAnimation:self];
	
	[self performSelector:@selector(setupWithPreference) withObject:nil afterDelay:0.0f];
}

- (void)setupWithPreference
{
	[self setup:[[NSUserDefaults standardUserDefaults] boolForKey:kFullscreenKey]];
}

- (void)willTerminate
{

}

- (void)dealloc
{

	
	[_scene release];

	[window orderOut:self];

	[window setContentView:nil];

	[pixelFormat release];

	[window release];
	[view release];

	[super dealloc];
}

- (Scene*)scene
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
- (BOOL)isInFullScreenMode
{ return NO; }

- (void)keyDown:(NSEvent *)theEvent
{
    unichar c = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];

	if ((([theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask) && (c == 'f'))
		[self setup:0];

	@synchronized(pressedKeys)
	{
		[pressedKeys addObject:$numui([theEvent keyCode])];
	}
	[[_scene simulator] keyDown:theEvent];
}
- (void)keyUp:(NSEvent *)theEvent
{
	@synchronized(pressedKeys)
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
