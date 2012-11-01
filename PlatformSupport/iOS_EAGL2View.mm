/*

 File: iPhoneEAGL2View.m
 Abstract: Convenience class that wraps the CAEAGLLayer from CoreAnimation into a
 UIView subclass.

 Version: 1.7

 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.

 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.

 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 Copyright (C) 2008 Apple Inc. All Rights Reserved.

 */

#import "Core3D.h"
#import "iPhoneEAGL2View.h"
#import "Game.h"


UIAccelerationValue accelerometerGravity[3];
UIAccelerationValue accelerometerChanges[3];
NSMutableArray *activeTouches;
BOOL wasShaking = FALSE;
#define kAccelerometerFrequency        30 // Hz

// TODO: port the iOS backend to use a RenderViewController too

//CLASS IMPLEMENTATIONS:
@implementation iPhoneEAGL2View

@synthesize delegate = _delegate, autoresizesSurface = _autoresize, surfaceSize = _size, framebuffer = _framebuffer, pixelFormat = _format, depthFormat = _depthFormat, context = _context;

+ (Class)layerClass
{
	return [CAEAGLLayer class];
}

- (void)_destroySurface
{
	EAGLContext *oldContext = [EAGLContext currentContext];

	if (oldContext != _context)
		[EAGLContext setCurrentContext:_context];

	if (_depthFormat)
	{
		glDeleteRenderbuffers(1, &depthbuffer);
		depthbuffer = 0;
	}

	glDeleteRenderbuffers(1, &resolveColorbuffer);
	resolveColorbuffer = 0;

	glDeleteRenderbuffers(1, &msaaColorbuffer);
	msaaColorbuffer = 0;

	glDeleteFramebuffers(1, &resolveFramebuffer);
	resolveFramebuffer = 0;

	glDeleteFramebuffers(1, &msaaFramebuffer);
	msaaFramebuffer = 0;

	if (oldContext != _context)
		[EAGLContext setCurrentContext:oldContext];
}

- (BOOL)_createSurface
{
#ifdef IPHONE
    int requestedSamples = (fastDevice) ? 4 : 0;
#else
	int requestedSamples = (fastDevice) ? 2 : 0;
#endif

	CAEAGLLayer *eaglLayer = (CAEAGLLayer *) [self layer];
	CGSize newSize;


	if (![EAGLContext setCurrentContext:_context])
	{
		return NO;
	}

	newSize = [eaglLayer bounds].size;
	newSize.width = roundf(newSize.width);
	newSize.height = roundf(newSize.height);
	int width = newSize.width;
	int height = newSize.height;

	assert(!resolveFramebuffer);

	/* Create the Resolve Framebuffer */
	glGenFramebuffers(1, &resolveFramebuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, resolveFramebuffer);


	/* Create the renderbuffer that is attached to CoreAnimation, and query the dimensions */
	glGenRenderbuffers(1, &resolveColorbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, resolveColorbuffer);
	[_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *) self.layer];
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, resolveColorbuffer);


	//  NSLog(@"created framebuffer of dimensions %d x %d", width, height);

	if (requestedSamples > 0)
	{
		/* Determine how many MSAS samples to use */
		GLint maxSamplesAllowed;
		glGetIntegerv(GL_MAX_SAMPLES_APPLE, &maxSamplesAllowed);
		int samplesToUse = (requestedSamples > maxSamplesAllowed) ? maxSamplesAllowed : requestedSamples;

		/* Create the MSAA framebuffer (offscreen) */
		glGenFramebuffers(1, &msaaFramebuffer);
		glBindFramebuffer(GL_FRAMEBUFFER, msaaFramebuffer);


		/* Create the offscreen MSAA color buffer.
* After rendering, the contents of this will be blitted into resolveColorbuffer */
		glGenRenderbuffers(1, &msaaColorbuffer);
		glBindRenderbuffer(GL_RENDERBUFFER, msaaColorbuffer);
		glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, samplesToUse, GL_RGB5_A1, width, height);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, msaaColorbuffer);


		/* Create the MSAA depth buffer (if desired) */
		{
			glGenRenderbuffers(1, &depthbuffer);
			glBindRenderbuffer(GL_RENDERBUFFER, depthbuffer);
			glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, samplesToUse, _depthFormat, width, height);
			glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthbuffer);
		}


		/* Validate the MSAA framebuffer */
		if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
		{
			NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
			[self _destroySurface];
			abort();
		}


		multisampled = TRUE;
	}
	else
	{
		msaaFramebuffer = 0;
		msaaColorbuffer = 0;

		/* Not multisampled, so create a single sample depth buffer attached directly to resolveFramebuffer */
		{
			glGenRenderbuffers(1, &depthbuffer);
			glBindRenderbuffer(GL_RENDERBUFFER, depthbuffer);
			glRenderbufferStorage(GL_RENDERBUFFER, _depthFormat, width, height);
			glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthbuffer);
		}

		multisampled = FALSE;
	}


	/* Validate the resolve framebuffer */
	glBindFramebuffer(GL_FRAMEBUFFER, resolveFramebuffer);
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
	{
		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
		[self _destroySurface];
		abort();
	}



	_size = newSize;

	myViewport(0, 0, newSize.width, newSize.height);
	glScissor(0, 0, newSize.width, newSize.height);


	[_delegate didResizeEAGLSurfaceForView:self];



	return YES;
}

//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder *)coder
{
	if ((self = [super initWithCoder:coder]))
	{
		CAEAGLLayer *eaglLayer = (CAEAGLLayer *) [self layer];

		_format = kEAGLColorFormatRGB565;
		_depthFormat = GL_DEPTH_COMPONENT16; //  GL_DEPTH_COMPONENT24_OES;

		[eaglLayer setDrawableProperties:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, _format, kEAGLDrawablePropertyColorFormat, nil]];


		_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		if (_context == nil)
		{
			[self release];
			return nil;
		}

#ifndef TARGET_IPHONE_SIMULATOR
        NSString *renderer = [NSString stringWithUTF8String:(const char *)glGetString(GL_RENDERER)];
        if (!CONTAINS(renderer, @"PowerVR SGX 535"))
        {
            fastDevice = TRUE;
        }
#endif

		if (![self _createSurface])
		{
			[self release];
			return nil;
		}


		self.multipleTouchEnabled = YES;



		[self performSelector:@selector(start) withObject:nil afterDelay:1.0];
	}

	return self;
}

- (void)stop
{
	if (displayLink)
	{
		[displayLink invalidate];
		displayLink = nil;
	}
#ifndef RELEASEBUILD
	if (fpsTimer)
	{
		[fpsTimer invalidate];
		fpsTimer = nil;
	}
#endif
}

- (void)drawView
{
	if (multisampled)
		glBindFramebuffer(GL_FRAMEBUFFER, msaaFramebuffer);


	[_scene update:CFAbsoluteTimeGetCurrent()];
	[_scene render];



	if (multisampled)
	{
		glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, msaaFramebuffer);
		glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, resolveFramebuffer);
		glResolveMultisampleFramebufferAPPLE();
	}

	GLenum attachments[] = {GL_COLOR_ATTACHMENT0, GL_DEPTH_ATTACHMENT};
	glDiscardFramebufferEXT(GL_FRAMEBUFFER, 2, attachments);

	if (multisampled)
	{
		glBindRenderbuffer(GL_RENDERBUFFER, resolveColorbuffer);
	}

	if (![_context presentRenderbuffer:GL_RENDERBUFFER])
		printf("Failed to swap renderbuffer in %s\n", __FUNCTION__);
}

#ifndef RELEASEBUILD
- (void)fpsTimer
{
	static unsigned int lastFrames = globalInfo.frame;

	if (globalInfo.frame > lastFrames)
	{
		globalInfo.fps = (globalInfo.frame - lastFrames);
		lastFrames = globalInfo.frame;
		printf("FPS: %i\tRenderedFaces: %i VisitedNodes: %i DrawCalls: %i\n",
				(int) globalInfo.fps,
				globalInfo.renderedFaces,
				globalInfo.visitedNodes,
				globalInfo.drawCalls);
	}
}
#endif

- (void)start
{
	// CADisplayLink is API new to iPhone SDK 3.1. Compiling against earlier versions will result in a warning, but can be dismissed
	// if the system version runtime check for CADisplayLink exists in -initWithCoder:. The runtime check ensures this code will
	// not be called in system versions earlier than 3.1.

	displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawView)];
	[displayLink setFrameInterval:fastDevice ? 1 : 2];
	[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];


#ifndef RELEASEBUILD
	fpsTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(fpsTimer) userInfo:nil repeats:YES];
#endif


	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kAccelerometerFrequency)];
	[[UIAccelerometer sharedAccelerometer] setDelegate:self];

	[self becomeFirstResponder];



	glBindFramebuffer(GL_FRAMEBUFFER, resolveFramebuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, resolveColorbuffer);



	pressedKeys = [[NSMutableArray alloc] initWithCapacity:5];
	activeTouches = [[NSMutableArray alloc] initWithCapacity:5];

	_scene = [[Scene alloc] init];

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	[_scene reshape:CGSizeMake([self bounds].size.width, [self bounds].size.height)];



	[Game renderSplash];
	if (![_context presentRenderbuffer:GL_RENDERBUFFER])
		printf("Failed to swap renderbuffer in %s\n", __FUNCTION__);



	id sim = [[NSClassFromString([[NSBundle mainBundle] objectForInfoDictionaryKey:@"SimulationClass"]) alloc] init];
	if (sim)
	{

		[_scene setSimulator:sim];
		[sim release];
	}
	else
		NSLog(@"no sim");



	[_scene reshape:CGSizeMake([self bounds].size.width, [self bounds].size.height)];

	[self setAlpha:1.0];
	[self setOpaque:YES];



	//	globalSettings.displayFPS = 1;
}

- (void)dealloc
{
//	NSLog(@"eagl dealloc");
	[[UIAccelerometer sharedAccelerometer] setDelegate:nil];

	[self _destroySurface];

	[_context release];
	_context = nil;

	[pressedKeys release];
	pressedKeys = nil;

	[activeTouches release];
	activeTouches = nil;

	[_scene release];
	_scene = nil;

	[super dealloc];
}

- (void)layoutSubviews
{
	CGRect bounds = [self bounds];

	if (_autoresize && ((roundf(bounds.size.width) != _size.width) || (roundf(bounds.size.height) != _size.height)))
	{
		[self _destroySurface];

		NSDebugLog(@"Resizing surface from %fx%f to %fx%f", _size.width, _size.height, roundf(bounds.size.width), roundf(bounds.size.height));

		[self _createSurface];
	}
}

- (void)setAutoresizesEAGLSurface:(BOOL)autoresizesEAGLSurface
{
	_autoresize = autoresizesEAGLSurface;
	if (_autoresize)
		[self layoutSubviews];
}

//- (void)setCurrentContext
//{
//	if(![EAGLContext setCurrentContext:_context]) {
//		printf("Failed to set current context %p in %s\n", _context, __FUNCTION__);
//	}
//}
//
//- (BOOL)isCurrentContext
//{
//	return ([EAGLContext currentContext] == _context ? YES : NO);
//}
//
//- (void)clearCurrentContext
//{
//	if(![EAGLContext setCurrentContext:nil])
//		printf("Failed to clear current context in %s\n", __FUNCTION__);
//}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
	[[scene simulator] accelerometer:accelerometer didAccelerate:acceleration];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[activeTouches addObjectsFromArray:[touches allObjects]];

	[[_scene simulator] touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[activeTouches removeObjectsInArray:[touches allObjects]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[activeTouches removeObjectsInArray:[touches allObjects]];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
	if (event.subtype == UIEventSubtypeMotionShake)
		wasShaking = TRUE;
}

- (BOOL)canBecomeFirstResponder
{
	return YES;
}
@end