//
//  Editorsimulation.h
//  Core3D-Editor
//
//  Created by CoreCode on 10.06.09.
//  Copyright 2009 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#import "Core3D.h"
#import "Editor.h"


@interface Editorsimulation : Simulation
{
    NSMutableData *ghostData;
    NSTimer *recordGhostTimer;
    float speed;
    Simulation *realsimulator;
    Camera *realcamera;
}

@property (retain, nonatomic) Simulation *realsimulator;
@property (retain, nonatomic) Camera *realcamera;

- (void)update;
- (void)render;
- (void)stopCamera;
- (void)recordGhostTimer:(NSTimer *)theTimer;

- (void)mouseDragged:(NSEvent *)theEvent;
- (void)scrollWheel:(NSEvent *)theEvent;
@end
