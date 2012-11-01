//
//  MacRenderViewController.h
//  Core3D
//
//  Created by CoreCode on 24.10.10.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//  Copyright (C) 2010 Apple Inc. Contains Apple Inc. Sample code
//



@class Scene;

#import <QuartzCore/CVDisplayLink.h>


@class RenderViewController;

@interface DisplayLinkOpenGLView : NSView
{
	NSSize reducedResolution;
	
	NSOpenGLContext *openGLContext;
	
	RenderViewController *controller;
	
	CVDisplayLinkRef displayLink;
	
	short frames;
	
	BOOL hasReducedResolution;
	
	NSTimer *fpsTimer;
	
#ifndef RELEASEBUILD
	NSMutableArray *fpsArray;
#endif
}

- (id)initWithFrame:(NSRect)frameRect __attribute__((__noreturn__));
- (id)initWithFrame:(NSRect)frameRect shareContext:(NSOpenGLContext *)context pixelFormat:(NSOpenGLPixelFormat *)pixelFormat;

- (void)drawView;

- (void)startAnimation;
- (void)stopAnimation;
#ifndef RELEASEBUILD
- (void)fpsTimer;
#endif
@property (nonatomic, assign) BOOL hasReducedResolution;
@property (nonatomic, retain) NSOpenGLContext *openGLContext;
@property (nonatomic, assign) RenderViewController *controller;
@end


@interface KeyWindow : NSWindow
{}
@end

@interface RenderViewController : NSResponder
{
	IBOutlet NSWindow *loadingWindow;
	IBOutlet NSProgressIndicator *loadingProgress;

	BOOL isInFullScreenMode;

	KeyWindow *window;

	DisplayLinkOpenGLView *windowedView;
	DisplayLinkOpenGLView *fullscreenView;
	DisplayLinkOpenGLView *currentView;

	NSOpenGLContext *baseContext;
	NSOpenGLPixelFormat *pixelFormat;

	Scene *_scene;
	BOOL isAnimating;
	CFAbsoluteTime renderTime;
}

+ (RenderViewController *)sharedController;
- (void)setup:(BOOL)fullscreen;
- (void)render;
- (void)reshape:(CGSize)size;
- (void)updateForFrameTime:(CFAbsoluteTime)time;
- (void)willTerminate:(NSNotification *)noti;

@property (nonatomic, readonly) BOOL isInFullScreenMode;
@property (nonatomic, readonly) KeyWindow *window;
@property (nonatomic, readonly) NSWindow *loadingWindow;
@property (nonatomic, readonly) NSOpenGLPixelFormat *pixelFormat;
@end
