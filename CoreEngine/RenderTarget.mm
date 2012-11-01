//
//  RenderTarget.m
//  Core3D
//
//  Created by CoreCode on 15.12.10.
//  Copyright 2010 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


#import "Core3D.h"
#import "RenderTarget.h"


@implementation RenderTarget

@synthesize bounds, previousBounds;

- (id)init
{
	return [self initWithWidthMultiplier:1.0 andHeightMultiplier:1.0];
}

- (id)initWithFixedWidth:(float)_width andFixedHeight:(float)_height
{
	if ((self = [super init]))
	{
		bounds.width = _width;
		bounds.height = _height;

		fixedSize = YES;

		[scene addRenderTarget:self];
	}
	return self;
}

- (id)initWithWidthMultiplier:(float)_widthMultiplier andHeightMultiplier:(float)_heightMultiplier
{
	if ((self = [super init]))
	{
		wm = _widthMultiplier;
		hm = _heightMultiplier;

		bounds.width = [scene bounds].width * wm;
		bounds.height = [scene bounds].height * hm;

		fixedSize = NO;

		[scene addRenderTarget:self];
	}
	return self;
}

- (CGRect)frame
{
	return CGRectMake(0, 0, bounds.width, bounds.height);
}

- (void)reshape:(CGSize)size
{

	previousBounds = bounds;
	if (!fixedSize)
	{
		bounds.width = size.width * wm;
		bounds.height = size.height * hm;
		//	NSLog(@"RenderTarget reshape from %@ to %@", NSStringFromSize(NSSizeFromCGSize(previousBounds)), NSStringFromSize(NSSizeFromCGSize(bounds)));
	}
}

- (NSString *)description
{
	return [NSString stringWithString:$stringf(@"<RenderTarget: %p fixedSize %i wm %f hm %f width %f height %f>", self, fixedSize, wm, hm, bounds.width, bounds.height)];
}

- (void)bind
{
}

- (void)unbind
{
}

- (void)dealloc
{
	[scene removeRenderTarget:self];

	[super dealloc];
}
@end
