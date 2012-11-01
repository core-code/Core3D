//
//  SceneNode.m
//  Core3D
//
//  Created by CoreCode on 21.11.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


#import "Core3D.h"


#ifdef TARGET_OS_MAC
#import "MacRenderViewController.h"
#endif

@implementation SceneNode

@synthesize scale, position, rotation, relativeModeTarget, relativeModeAxisConfiguration, axisConfiguration, children, enabled, name;

- (id)init
{
	if ((self = [super init]))
	{
//#if defined(TARGET_OS_MAC) && defined(DEBUG)
//        if (![[RenderViewController sharedController] loadingWindow] && [NSThread isMainThread]) fatal("doing things on main instead of render thread");
//#endif

		axisConfiguration = kYXZRotation;
		relativeModeAxisConfiguration = kYXZRotation;
		relativeModeTarget = nil;
		children = (MutableSceneNodeArray *) [[NSMutableArray alloc] initWithCapacity:5];
		enabled = YES;
		name = @"";
		scale = 1.0f;
	}

	return self;
}

- (void)update
{
#if !defined(RELEASEBUILD) && !defined(TARGET_OS_IPHONE)
    uint64_t micro = GetNanoseconds() / 1000;
#endif

	if (enabled)
		[self updateNode];

#ifndef DISABLE_SOUND
	[self updateSound];
#endif

#if !defined(RELEASEBUILD) && !defined(TARGET_OS_IPHONE)
    uint64_t post = GetNanoseconds() / 1000;

    if (globalInfo.frame > 10 && ((post-micro) / 1000.0) > 2.0)
    {
		NSString *_name = [self description];
		if ([self respondsToSelector:@selector(name)])
			_name = [(Mesh*)self name];
        NSLog(@"updating sn %@ (%@) took %f (frame: %lu)", NSStringFromClass([self class]), _name, (post-micro) / 1000.0, (unsigned long)globalInfo.frame);
    }
#endif

	[children makeObjectsPerformSelector:@selector(update)];
}

- (SceneNode *)childWithName:(NSString *)_name
{
	if ([name isEqualToString:_name])
		return self;
	else
	{
		for (SceneNode *c in children)
		{
			SceneNode *n = [c childWithName:_name];
			if (n)
				return n;
		}
	}
	return nil;
}

- (NSArray *)allocListOfAllChildren
{
	NSMutableArray *_children;
#ifdef GNUSTEP
    _children = [[NSMutableArray alloc] init];
#else
	_children = (NSMutableArray *) CFArrayCreateMutable(kCFAllocatorDefault, 5, NULL);
#endif


	for (SceneNode *sn in children)
	{
		[_children addObject:sn];

		NSArray *grandChildren = [sn allocListOfAllChildren];
		[_children addObjectsFromArray:grandChildren];
		[grandChildren release];
	}

	return _children;
}

- (NSString *)description
{
	return $stringf(@"<%@ %p>\n position: %f %f %f\n rotation: %f %f %f \n children:%@",
					[self class], self,
					position[0], position[1], position[2],
					rotation[0], rotation[1], rotation[2],
					[children description]);
}

- (void)transform
{
	if (relativeModeTarget != nil)
	{
		[currentCamera translate:[relativeModeTarget position]];
		[currentCamera rotate:[relativeModeTarget rotation] withConfig:relativeModeAxisConfiguration];
	}

	[currentCamera translate:position];
	[currentCamera rotate:rotation withConfig:axisConfiguration];
	if (scale != 1.0f)
		[currentCamera scale:scale];
}

- (void)render
{
//#if defined(TARGET_OS_MAC) && defined(DEBUG)
//    if (![[RenderViewController sharedController] loadingWindow] && [NSThread isMainThread]) fatal("doing things on main instead of render thread");
//#endif


	if (enabled)
	{
		[currentCamera push];

		[self transform];

#if !defined(RELEASEBUILD) && !defined(TARGET_OS_IPHONE)
		uint64_t micro = GetNanoseconds() / 1000;
#endif
		[self renderNode];

#if !defined(RELEASEBUILD) && !defined(TARGET_OS_IPHONE)
		uint64_t post = GetNanoseconds() / 1000;

		if (globalInfo.frame > 10 && ((post-micro) / 1000.0) > 5.0)
		{
			NSString *_name = [self description];

			if ([self respondsToSelector:@selector(name)])
				 _name = [(Mesh*)self name];
			NSLog(@"Info: rendering sn %@ (%@) took %f (frame: %lu)", NSStringFromClass([self class]), _name, (post-micro) / 1000.0, (unsigned long)globalInfo.frame);
		}
#endif

		[children makeObjectsPerformSelector:@selector(render)];


		[currentCamera pop];
	}
}

- (void)removeNode:(SceneNode *)node
{
	[children removeObject:node];

	for (SceneNode *child in children)
		[child removeNode:node];
}

- (void)reshape:(CGSize)size
{
//#if defined(TARGET_OS_MAC) && defined(DEBUG)
//    if (![[RenderViewController sharedController] loadingWindow] && [NSThread isMainThread]) fatal("doing things on main instead of render thread");
//#endif

	[self reshapeNode:size];
	for (SceneNode *child in children)
		[child reshape:size];
}

- (void)updateNode
{}

- (void)renderNode
{}

- (void)reshapeNode:(CGSize)size
{}

- (vector3f)aggregatePosition
{
	if (relativeModeTarget != nil)
	{
		matrix44f_c m;
		matrix_translation(m, [relativeModeTarget position]);
		for (uint8_t i = 0; i < 3; i++)
		{
			uint8_t axis = (relativeModeAxisConfiguration >> (i * 2)) & 3;

			if ((axis != kDisabledAxis) && ([relativeModeTarget rotation][axis] != 0))
				matrix_rotate_about_local_axis(m, axis, cml::rad([relativeModeTarget rotation][axis]));
		}
		matrix44f_c ms;
		matrix_translation(ms, position);
		m *= ms;
		return matrix_get_translation(m);
	}
	else
		return position;
}

//- (vector3f)aggregateRotation
//{
//	if (relativeModeTarget != nil)
//		return rotation + [relativeModeTarget rotation];
//	else
//		return rotation;
//}

- (void)setRotationFromLookAt:(vector3f)lookAt
{
	static const vector3f forward = vector3f(0, 0, -1);

	vector3f direction = lookAt - [self aggregatePosition];
	vector3f direction_without_y = vector3f(direction[0], 0, direction[2]);

	float yrotdeg = cml::deg(unsigned_angle(forward, direction_without_y));
	float xrotdeg = cml::deg(unsigned_angle(direction_without_y, direction));

	if (relativeModeTarget != nil)
	{
		if ([relativeModeTarget rotation].length() > 0.01)
			NSLog(@"Warning: setRotationFromLookAt for target mode with rotation broken"); // TODO: fix this
	}

	rotation[0] = direction[1] > 0 ? xrotdeg : -xrotdeg;
	rotation[1] = direction[0] > 0 ? -yrotdeg : yrotdeg;
	rotation[2] = 0;
}

- (void)setPositionByMovingForward:(float)amount
{
	position += [self getLookAt] * amount;
}

- (vector3f)getTransformedVector:(vector3f)input
{
	matrix33f_c m;
	cml::identity_transform(m);


	if (relativeModeTarget != nil)
	{
		vector3f theirRot = [relativeModeTarget rotation];

		for (uint8_t i = 0; i < 3; i++)
		{
			uint8_t axis = (relativeModeAxisConfiguration >> (i * 2)) & 3;

			if ((axis != kDisabledAxis) && (theirRot[axis] != 0))
				matrix_rotate_about_local_axis(m, axis, cml::rad(theirRot[axis]));
		}
	}

	for (uint8_t i = 0; i < 3; i++)
	{
		uint8_t axis = (axisConfiguration >> (i * 2)) & 3;

		if ((axis != kDisabledAxis) && (rotation[axis] != 0))
			matrix_rotate_about_local_axis(m, axis, cml::rad(rotation[axis]));
	}

	return transform_vector(m, input);
}

- (vector3f)getLookAt
{
	static const vector3f forward = vector3f(0, 0, -1);

	return [self getTransformedVector:forward];
}

- (vector3f)getUp
{
	static const vector3f up = vector3f(0, 1, 0);

	return [self getTransformedVector:up];
}

- (void)dealloc
{
#if defined(TARGET_OS_MAC) && defined(DEBUG) && !defined(SDL)
    if (![[RenderViewController sharedController] loadingWindow] && [NSThread isMainThread]) fatal("doing things on main instead of render thread");
#endif

	//   NSLog(@"sn release %@", name);

	[name release];
	[children release];

	if ([self respondsToSelector:@selector(deallocSound)])
		[self performSelector:@selector(deallocSound)];

	[super dealloc];
}

CPPPROPERTYSUPPORT_V3_M(position, Position)
CPPPROPERTYSUPPORT_V3_M(rotation, Rotation)
@end
