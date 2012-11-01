//
//  Simulation.m
//  Core3D
//
//  Created by CoreCode on 30.10.10.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


#import "Core3D.h"
#ifndef TARGET_OS_IPHONE
#import "Editor.h"
#endif

@implementation Simulation

@synthesize paused;
@synthesize simTime;

- (id)init
{
	if ((self = [super init]))
	{
#ifdef __BLOCKS__
		delayedActionBlocks = [[NSMutableArray alloc] init];
		animationBlocks = [[NSMutableArray alloc] init];
		timerBlocks = [[NSMutableArray alloc] init];

		tmpTimerBlocks = [[NSMutableArray alloc] init];
		tmpDelayedActionBlocks = [[NSMutableArray alloc] init];
		tmpAnimationBlocks = [[NSMutableArray alloc] init];
		
		tmpRenderActionBlocks = [[NSMutableArray alloc] init];
		renderActionBlocks = [[NSMutableArray alloc] init];
#endif
		paused = FALSE;
	}
	return self;
}

- (void)dealloc
{
#ifdef __BLOCKS__
	[delayedActionBlocks release];
	[animationBlocks release];
	[timerBlocks release];

	[tmpTimerBlocks release];
	[tmpDelayedActionBlocks release];
	[tmpAnimationBlocks release];
	
	[tmpRenderActionBlocks release];
	[renderActionBlocks release];
#endif
	[super dealloc];
}

#ifdef __BLOCKS__
- (void)addAnimationWithDuration:(NSTimeInterval)duration animation:(DoubleInBlock)animationBlock completion:(BasicBlock)cleanupBlock
{
	DoubleInBlock anim = [animationBlock copy];
	BasicBlock clean = [cleanupBlock copy];

	NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:$numd(simTime), @"starttime",
	                                                                  $numd(simTime + duration), @"endtime",
	                                                                  anim, @"animationblock",
	                                                                  clean, @"cleanupblock", nil];

	[tmpAnimationBlocks addObject:dict];
	[dict release];
	[anim release];
	[clean release];
}

- (void)addTimerWithInterval:(NSTimeInterval)interval timer:(DoubleInBlock)timerBlock completion:(BasicBlock)cleanupBlock endCondition:(BoolOutBlock)conditionBlock
{
	BoolOutBlock cond = [conditionBlock copy];
	DoubleInBlock timer = [timerBlock copy];
	BasicBlock clean = [cleanupBlock copy];

	NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:$numd(simTime), @"starttime",
	                                                                                $numd(0.0), @"performtime",
	                                                                                $numd(interval), @"interval",
	                                                                                cond, @"conditionblock",
	                                                                                timer, @"animationblock",
	                                                                                clean, @"cleanupblock", nil];

	[tmpTimerBlocks addObject:dict];

	[dict release];
	[timer release];
	[clean release];
	[cond release];
}

- (void)performBlockAfterDelay:(NSTimeInterval)delay block:(BasicBlock)_block
{
	@synchronized (self)
	{
		BasicBlock block = [_block copy];
		NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:$numd(simTime + delay), @"endtime", block, @"block", nil];


		[tmpDelayedActionBlocks addObject:dict];


		[dict release];
		[block release];
	}
}

- (void)performBlockOnRenderThread:(BasicBlock)_block
{
	@synchronized (self)
	{
		BasicBlock block = [_block copy];
		
		
		[tmpRenderActionBlocks addObject:block];
		
		
		[block release];
	}
}
#endif

- (void)update
{
	// NSLog(@"sim up start");

	simTime += globalInfo.frameDiff;
//    if (simTime < 0.0)
//        cout << simTime << endl;

#ifdef __BLOCKS__

	@synchronized (self)
	{
		for (id item in tmpTimerBlocks) [timerBlocks addObject:item];
		for (id item in tmpAnimationBlocks) [animationBlocks addObject:item];
		for (id item in tmpDelayedActionBlocks) [delayedActionBlocks addObject:item];

		[tmpAnimationBlocks removeAllObjects];
		[tmpDelayedActionBlocks removeAllObjects];
		[tmpTimerBlocks removeAllObjects];
	}
	// delayed action
	NSMutableArray *blocksToRemove = [[NSMutableArray alloc] init];
	for (NSDictionary *dict in delayedActionBlocks)
	{
		if (simTime > [[dict objectForKey:@"endtime"] doubleValue])
		{
			[blocksToRemove addObject:dict];
			BasicBlock block = [dict objectForKey:@"block"];


			block();
		}
	}

	[delayedActionBlocks removeObjectsInArray:blocksToRemove];
	[blocksToRemove removeAllObjects];

	// animation
	for (NSDictionary *dict in animationBlocks)
	{
		NSNumber *endTime = [dict objectForKey:@"endtime"];

		if ((endTime && simTime > [endTime doubleValue]))
//            || (!endTime && ((BoolOutBlock)[dict objectForKey:@"completionblock"])()))
		{
			[blocksToRemove addObject:dict];

			BasicBlock block = [dict objectForKey:@"cleanupblock"];

			// NSLog(@"executing  cleanup block at %f", simTime);
			block();
		}
		else
		{
			DoubleInBlock block = [dict objectForKey:@"animationblock"];

			block(simTime - [[dict objectForKey:@"starttime"] doubleValue]);
		}
	}
	[animationBlocks removeObjectsInArray:blocksToRemove];
	[blocksToRemove removeAllObjects];


	// timers
	for (NSMutableDictionary *dict in timerBlocks)
	{
		if (((BoolOutBlock) [dict objectForKey:@"conditionblock"])())
		{
			[blocksToRemove addObject:dict];
			BasicBlock block = [dict objectForKey:@"cleanupblock"];

			block();
		}
		else
		{
			NSNumber *performtime = [dict objectForKey:@"performtime"];
			NSNumber *interval = [dict objectForKey:@"interval"];

			if ([performtime doubleValue] + [interval doubleValue] < simTime)
			{
				DoubleInBlock block = [dict objectForKey:@"animationblock"];

				block(simTime - [[dict objectForKey:@"starttime"] doubleValue]);
				[dict setObject:$numd(simTime) forKey:@"performtime"];
			}
		}
	}
	[timerBlocks removeObjectsInArray:blocksToRemove];

	[blocksToRemove removeAllObjects];
	[blocksToRemove release];
#endif
}

- (void)render
{
#ifdef __BLOCKS__
	@synchronized (self)
	{
		for (id item in tmpRenderActionBlocks)
		{
			[renderActionBlocks addObject:item];
		}

		[tmpRenderActionBlocks removeAllObjects];
	}

	for (BasicBlock block in renderActionBlocks)
	{			
		block();
	}
	

	[renderActionBlocks removeAllObjects];
#endif
}

#ifndef TARGET_OS_IPHONE
- (void)keyDown:(NSEvent *)theEvent
{
#ifndef RELEASEBUILD
	unichar c = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
	
	if ((([theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask) && (c == 'e'))
	{
		[Editor loadEditor:self];
	}
#endif
}

- (void)keyUp:(NSEvent *)theEvent
{
}

- (void)mouseDown:(NSEvent *)theEvent
{
}

- (void)mouseUp:(NSEvent *)theEvent
{
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
}

- (void)mouseDragged:(NSEvent *)theEvent
{
}

- (void)scrollWheel:(NSEvent *)theEvent
{
}
#else
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
}
#endif

@end
