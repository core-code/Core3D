//
//  SDLRenderViewController.h
//  Core3D
//
//  Created by CoreCode on 24.10.10.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see _MIT_LICENSE.txt
//  Copyright (C) 2010 Apple Inc. Contains Apple Inc. Sample code
//



@class Scene;

@interface RenderViewController : NSObject
{
	Scene *scene;
	BOOL done;
	NSString *nib;
}

+ (RenderViewController *)sharedController;

- (void)quitAndLoadNib:(NSString *)nib;

@end
