//
//  Simulation.h
//  Core3D
//
//  Created by CoreCode on 30.10.10.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//



@interface Simulation : NSObject
{
	double simTime;
	BOOL paused;


#ifdef __BLOCKS__
	NSMutableArray *tmpRenderActionBlocks;
	NSMutableArray *renderActionBlocks;

	
	NSMutableArray *delayedActionBlocks;
	NSMutableArray *animationBlocks;
	NSMutableArray *timerBlocks;

	NSMutableArray *tmpDelayedActionBlocks;
	NSMutableArray *tmpAnimationBlocks;
	NSMutableArray *tmpTimerBlocks;
#endif
}

#ifdef __BLOCKS__
- (void)performBlockOnRenderThread:(BasicBlock)_block;

- (void)performBlockAfterDelay:(NSTimeInterval)delay block:(BasicBlock)block;

- (void)addAnimationWithDuration:(NSTimeInterval)duration animation:(DoubleInBlock)animationBlock completion:(BasicBlock)cleanupBlock;

- (void)addTimerWithInterval:(NSTimeInterval)time timer:(DoubleInBlock)timerBlock completion:(BasicBlock)cleanupBlock endCondition:(BoolOutBlock)conditionBlock;
#endif

- (void)update;
- (void)render;

#ifndef TARGET_OS_IPHONE
- (void)keyDown:(NSEvent *)theEvent;
- (void)keyUp:(NSEvent *)theEvent;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)mouseUp:(NSEvent *)theEvent;
- (void)rightMouseDown:(NSEvent *)theEvent;
- (void)rightMouseUp:(NSEvent *)theEvent;
- (void)mouseDragged:(NSEvent *)theEvent;
- (void)scrollWheel:(NSEvent *)theEvent;
#else
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration;
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
#endif

@property (nonatomic, assign) BOOL paused;
@property (nonatomic, readonly) double simTime;
@end
