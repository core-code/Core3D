//
//  PathNode.m
//  Core3D
//
//  Created by CoreCode on 07.05.08.
//  Copyright 2008 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#import "Core3D.h"
#import "PathNode.h"


@implementation PathNode

@synthesize trackPoints;

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithContentsOfURL:(NSURL *)_url
{
	if ((self = [self init]))
	{
		if (!_url)
			fatal("Error: can't load nil path");

		NSData *trackData = [NSData dataWithContentsOfURL:_url];
		if (!trackData) fatal("Error: loading path url failed");

		trackPath = (float *) malloc([trackData length]);
		trackPoints = (([trackData length] / 3) / sizeof(float));// - 1;
		[trackData getBytes:trackPath];
	}

	return self;
}

//- (void)renderNode
//{
//	[super renderNode];
//
//	GLint prog;
//	glDisable(GL_LIGHTING);
//	glGetIntegerv(GL_CURRENT_PROGRAM, &prog);
//	glUseProgram(0);
//
//	int i;
//	myColor(1.0f, 0.0f, 0.0f, 1.0f);
//	myPointSize(20);
//	glBegin(GL_POINTS);
////	glBegin(GL_LINE_STRIP);
//
//	for (i = 0; i < trackPoints; i++)
//	{
//		myColor(1.0f/(i+1), (float)i / (float)trackPoints, 1.0f, 1.0f);
//		glVertex3f(*(trackPath+(i)*3+0), *(trackPath+(i)*3+1) + 2, *(trackPath+(i)*3+2));
//	}
//
//
//	//	myColor(0.4, 0.1, 0.1, 1.0);
//	//	glVertex3f(TRACKX(currpoint), TRACKY(currpoint)+1.1, TRACKZ(currpoint));
//	glEnd();
//	globalInfo.drawCalls++;
//    /*DRAW_CALL*/
//
//	glEnable(GL_LIGHTING);
//	glUseProgram(prog);
//}
@end
