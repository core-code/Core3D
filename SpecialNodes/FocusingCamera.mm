//
//  FocusingCamera.m
//  Core3D
//
//  Created by CoreCode on 13.12.10.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#import "Core3D.h"
#import "FocusingCamera.h"


@implementation FocusingCamera

@synthesize fovFactor;

- (id)init
{
	if ((self = [super init]))
	{
		fovFactor = 2.0;
	}

	return self;
}

- (void)transform
{
	vector3f mostNegPoint = vector3f(FLT_MAX, FLT_MAX, FLT_MAX);
	vector3f mostPosPoint = vector3f(-FLT_MAX, -FLT_MAX, -FLT_MAX);

	NSArray *allObjects = [currentRenderPass newListOfAllObjects];

	for (Mesh *oc in allObjects) // build AABB of nodes visible from main camera - this is wrong
	{
		SceneNode *sn = oc;

//		if ([oc respondsToSelector:@selector(shadowmesh)])
//		{
//			oc = [oc performSelector:@selector(shadowmesh)];
//			if (!oc)
//				continue;
//		}
//		else 

		if (![oc isKindOfClass:[Mesh class]])
			continue;


		uint16_t i;
		uint16_t *vns = [oc visibleNodeStack];
		vector3f pos = [sn position];

		BOOL dynamic = FALSE;

		for (i = 0; i < (dynamic ? [oc visibleNodeStackTop] : 1); i++)
		{
			struct octree_node *node = (struct octree_node *) _NODE_NUM([oc octree], (dynamic ? vns[i] : 0));
			vector3f origin = vector3f(node->aabbOriginX, node->aabbOriginY, node->aabbOriginZ) + pos;
			vector3f extent = origin + vector3f(node->aabbExtentX, node->aabbExtentY, node->aabbExtentZ);

			if (origin[0] < mostNegPoint[0]) mostNegPoint[0] = origin[0];
			if (origin[1] < mostNegPoint[1]) mostNegPoint[1] = origin[1];
			if (origin[2] < mostNegPoint[2]) mostNegPoint[2] = origin[2];
			if (extent[0] > mostPosPoint[0]) mostPosPoint[0] = extent[0];
			if (extent[1] > mostPosPoint[1]) mostPosPoint[1] = extent[1];
			if (extent[2] > mostPosPoint[2]) mostPosPoint[2] = extent[2];
		}
	}
	[allObjects release];

	if ((mostNegPoint[0] != FLT_MAX) && (mostPosPoint[0] != -FLT_MAX))
	{
		vector3f sceneCenter = (mostNegPoint + mostPosPoint) * 0.5f;
		float sceneBoundingRadius = (mostPosPoint - mostNegPoint).length() * 0.5f;
		vector3f usToCenter = sceneCenter - [self aggregatePosition];
		float usToSceneDistance = usToCenter.length();
		float _nearPlane = usToSceneDistance - sceneBoundingRadius;
		float fieldOfView = cml::deg(fovFactor * atanf(sceneBoundingRadius / usToSceneDistance));
		float _farPlane = _nearPlane + (2.0f * sceneBoundingRadius);

		if (fieldOfView > 179)
			NSLog(@"Warning: shadowmap fieldOfView above 179!");
		if (_nearPlane < 1)
		{
			NSLog(@"Warning: shadowmap nearPlane below 1!");
			_nearPlane = 1;
		}


		if (_nearPlane != nearPlane || _farPlane != farPlane || fieldOfView != fov)
		{
			nearPlane = _nearPlane;
			farPlane = _farPlane;
			fov = fieldOfView;
			[self updateProjection];
		}
		[self setRotationFromLookAt:sceneCenter];
	}
//	NSLog(@"FOcusing %f %f %f", fov, nearPlane, farPlane);

	[super transform];
}
@end
