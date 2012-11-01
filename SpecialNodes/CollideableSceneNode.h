//
//  CollideableSceneNode.h
//  CoreBreach
//
//  Created by CoreCode on 17.03.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#include "btBulletCollisionCommon.h"
#include "btConvexCast.h"


@interface CollideableSceneNode : SceneNode <Collideable>
{
	btCollisionObject *collisionObject;
	btCollisionShape *currentShape;
	NSMutableDictionary *collisionAlgorithms;
}


- (void)setCollisionShapeSphere:(vector3f)extent atPosition:(vector3f)_position;
- (void)setCollisionShapeSphere:(vector3f)extent;
- (void)setCollisionShapeBox:(vector3f)extent;
- (void)resetState;

@property (nonatomic, readonly) btCollisionObject *collisionObject;
@end
