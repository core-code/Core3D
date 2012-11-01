//
//  RenderTarget.h
//  Core3D
//
//  Created by CoreCode on 15.12.10.
//  Copyright 2010 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//



@interface RenderTarget : NSObject
{
	CGSize previousBounds;
	CGSize bounds;
	BOOL fixedSize;
	float wm;
	float hm;
}

- (CGRect)frame;

@property (nonatomic, readonly) CGSize bounds;
@property (nonatomic, readonly) CGSize previousBounds;

- (id)initWithFixedWidth:(float)_width andFixedHeight:(float)_height;
- (id)initWithWidthMultiplier:(float)_widthMultiplier andHeightMultiplier:(float)_heightMultiplier;
- (void)reshape:(CGSize)size;
- (void)bind;
- (void)unbind;

@end
