//
//  CollideableMesh.h
//  Core3D
//
//  Created by CoreCode on 14.05.08.
//  Copyright 2008 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

@protocol Collideable

- (vector3f)intersectWithLineStart:(vector3f)startPoint end:(vector3f)endPoint;
- (TriangleIntersectionInfo)intersectWithNode:(SceneNode <Collideable> *)otherNode;
- (BOOL)intersectsWithNode:(SceneNode <Collideable> *)otherNode;
@property (nonatomic, readonly) btCollisionObject *collisionObject;

@end

@interface CollideableMesh : Mesh
{
	struct octree_struct *octree_collision;
}



- (void)setCollisionShapeFittingSphere;
- (void)setCollisionShapeSphere:(vector3f)extent;
- (void)setCollisionShapeBox:(vector3f)extent;
- (void)setCollisionShapeConvexHull:(BOOL)simplify;
- (void)setCollisionShapeTriangleMesh:(BOOL)gimpact;

- (vector3f)intersectWithLineStart:(vector3f)startPoint end:(vector3f)endPoint;
- (TriangleIntersectionInfo)intersectWithMesh:(CollideableMesh *)otherMesh;

@end


