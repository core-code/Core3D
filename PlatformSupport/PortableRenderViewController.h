//
//  PortableRenderViewController.h
//  Core3D
//
//  Created by CoreCode on 24.10.10.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see _MIT_LICENSE.txt
//  Copyright (C) 2010 Apple Inc. Contains Apple Inc. Sample code
//


@class Scene;

@class RenderViewController;

@interface PortableOpenGLView : NSOpenGLView
{
	NSDate *startDate;
	NSTimer *timer;
	RenderViewController	*controller;
}

@property (nonatomic, assign) RenderViewController *controller;

- (void)start;

@end


@interface RenderViewController : NSResponder
{
	IBOutlet NSWindow *loadingWindow;
	IBOutlet NSProgressIndicator *loadingProgress;
	NSWindow *window;

	PortableOpenGLView *view;

	NSOpenGLPixelFormat *pixelFormat;

	Scene *_scene;
}

+ (id)sharedController;
- (void)setup:(BOOL)fullscreen;
- (void)render;
- (void)reshape:(CGSize)size;
- (void)updateForFrameTime:(CFAbsoluteTime)time;
- (void)prepareOpenGL;

@property (nonatomic, readonly) NSWindow *window;
@property (nonatomic, readonly) NSOpenGLPixelFormat *pixelFormat;
@end
