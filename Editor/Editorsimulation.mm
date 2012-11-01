//
//  Editorsimulation.m
//  Core3D-Editor
//
//  Created by CoreCode on 10.06.09.
//  Copyright 2009 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#import "Editorsimulation.h"


extern Editor *gEditor;

@implementation Editorsimulation

@synthesize realsimulator, realcamera;

- (id)init
{
    if ((self = [super init]))
    {
        glClearColor(0.5, 0.7, 0.5, 1);

        [gEditor performSelector:@selector(reload:) withObject:self afterDelay:0.1];

        speed = 0.0f;
    }
    return self;
}

- (void)update
{
    [super update];

    [[[scene mainRenderPass] camera] setPositionByMovingForward:speed];
}

- (void)render
{
    for (NSNumber *keyHit in pressedKeys)
    {
        switch ([keyHit intValue])
        {
            case kVK_ANSI_S:
                [self stopCamera];
                break;

            case kVK_ANSI_KeypadPlus:
                [[scene mainRenderPass] camera].fov += 1.0f;
                break;

            case kVK_ANSI_KeypadMinus:
                [[scene mainRenderPass] camera].fov -= 1.0f;
                break;

            case kVK_ANSI_W:
                [[[scene mainRenderPass] camera] setPosition:[[[scene mainRenderPass] camera] position] + vector3f(0.0f, 0.1f, 0.0f)];
                break;
            case kVK_ANSI_Q:
                [[[scene mainRenderPass] camera] setPosition:[[[scene mainRenderPass] camera] position] - vector3f(0.0f, 0.1f, 0.0f)];
                break;
            case kVK_ANSI_A:
                [[[scene mainRenderPass] camera] setRotation:[[[scene mainRenderPass] camera] rotation] + vector3f(0.0f, 0.3f, 0.0f)];
                break;
            case kVK_ANSI_D:
                [[[scene mainRenderPass] camera] setRotation:[[[scene mainRenderPass] camera] rotation] - vector3f(0.0f, 0.3f, 0.0f)];
                break;
        }
    }
    [gEditor render];
	[super render];
}

- (void)stopCamera
{
    speed = 0.0f;
}

- (void)keyDown:(NSEvent *)theEvent
{
    unichar c = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];

    if ((([theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask) && (c == 'e'))
    {
#ifdef __BLOCKS__
        [self performBlockAfterDelay:0.0 block:^
        {
            [gEditor release];
            [[scene mainRenderPass] setCamera:realcamera];
            [scene setSimulator:realsimulator];
        }];
#endif
    }
    if (c == '+')
    {
        ghostData = [[NSMutableData alloc] initWithCapacity:3 * 4 * 30 * 120];
        recordGhostTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 / 30.0 target:self selector:@selector(recordGhostTimer:) userInfo:NULL repeats:YES] retain];
    }
    if (c == '-')
    {
        [ghostData writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"core3dcameraghost.ghost"] atomically:NO];

        [recordGhostTimer invalidate];
        [recordGhostTimer release];
        [ghostData release];
    }
}

- (void)recordGhostTimer:(NSTimer *)theTimer
{
    @synchronized ([[scene mainRenderPass] camera])
    {
        [ghostData appendBytes:[[[scene mainRenderPass] camera] position].data() length:3 * 4];
        [ghostData appendBytes:[[[scene mainRenderPass] camera] rotation].data() length:3 * 4];
    }
}

- (void)keyUp:(NSEvent *)theEvent
{
}

- (void)mouseDown:(NSEvent *)theEvent
{
}

- (void)dealloc
{
    [self setRealcamera:nil];
    [self setRealsimulator:nil];

    [super dealloc];
}

- (void)mouseUp:(NSEvent *)theEvent
{
#ifndef __COCOTRON__	
	[self performBlockOnRenderThread:^
	{
		if (![theEvent clickCount] || !currentCamera || !currentRenderPass)
			return;

		NSPoint grabOrigin = [theEvent locationInWindow];
		cml::vector3d rayOrigin, rayDirection;
		cml::make_pick_ray((double) grabOrigin.x, (double) grabOrigin.y, [currentCamera viewMatrix], [currentCamera projectionMatrix], [currentRenderPass viewportMatrix], rayOrigin, rayDirection, false);


		float minDist = FLT_MAX;
		Mesh *selection = nil;
		for (CollideableMeshBullet *mesh in[scene objects])
		{
			if ([mesh isKindOfClass:[CollideableMeshBullet class]])
			{
				vector3f inters = [mesh intersectWithLineStart:vector3f(rayOrigin) end:vector3f(rayDirection)];

				if (inters[0] != FLT_MAX)
				{
					float dist = length([[[scene mainRenderPass] camera] position] - inters);
					if (dist < minDist)
					{
						minDist = dist;
						selection = mesh;
					}
				}
			}
		}

#ifdef TARGET_OS_MAC
		 dispatch_async(dispatch_get_main_queue(), ^(void)
		{
#endif
			if (selection)
				[gEditor selectItem:selection];
#ifdef TARGET_OS_MAC
		});
#endif
	}];
#endif
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [gEditor mouseDragged:vector2f([theEvent deltaX], [theEvent deltaY]) withFlags:(uint32_t) [theEvent modifierFlags]];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
    speed += [theEvent deltaY] / 100.0f;
}
@end
