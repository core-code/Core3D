//
//  CollideableMeshBullet.h
//  Core3D
//
//  Created by CoreCode on 10.07.09.
//  Copyright 2009 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


#include "btBulletCollisionCommon.h"
#include "btShapeHull.h"
#include "btConvexCast.h"
#include "btGImpactShape.h"

#import "CollideableMesh.h"


@interface CollideableMeshBullet : Mesh <Collideable>
{
	btCollisionObject *collisionObject;
	struct octree_struct *octree_collision;
	btCollisionShape *currentShape;
	btTriangleIndexVertexArray *meshInterface;
	NSMutableDictionary *collisionAlgorithms;
}


- (void)setCollisionShapeSphere:(vector3f)extent atPosition:(vector3f)_position;
- (void)setCollisionShapeFittingSphere;
- (void)setCollisionShapeSphere:(vector3f)extent;
- (void)setCollisionShapeBox:(vector3f)extent;
- (void)setCollisionShapeConvexHull:(BOOL)simplify;
- (void)setCollisionShapeTriangleMesh:(BOOL)gimpact;
- (void)resetState;

@property (nonatomic, readonly) btCollisionObject *collisionObject;

@end
