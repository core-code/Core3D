//
//  QCNode.m
//  CoreBreach
//
//  Created by CoreCode on 15.11.10.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see _MIT_LICENSE.txt
//

#import "Core3D.h"
#import "QCNode.h"
#import "RenderViewController.h"


@implementation QCNode

- (id)initWithCompositionNamed:(NSString *)_name
{
	if ((self = [super init]))
	{
		renderer = [[QCRenderer alloc] initWithOpenGLContext:[NSOpenGLContext currentContext]
		                                         pixelFormat:[[RenderViewController sharedController] pixelFormat]
				                                        file:[[NSBundle mainBundle] pathForResource:_name ofType:@"qtz"]];
	} 

	return self;
}

- (void)renderNode
{
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity();


	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glLoadIdentity();


	static float time = 0.0;
	time += 1.0 / 60.0;

	[renderer renderAtTime:time arguments:nil];

	glMatrixMode(GL_PROJECTION);

	glPopMatrix();
	glMatrixMode(GL_MODELVIEW);
	glPopMatrix();
}
@end
