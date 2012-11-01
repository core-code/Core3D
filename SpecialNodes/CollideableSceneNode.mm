//
//  CollideableSceneNode.m
//  CoreBreach
//
//  Created by CoreCode on 17.03.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#import "Core3D.h"
#import "CollideableSceneNode.h"


extern btCollisionWorld *collisionWorld;

@implementation CollideableSceneNode

@synthesize collisionObject;

- (id)init
{
	if ((self = [super init]))
	{
		if (collisionWorld == 0)
		{
			btVector3 worldAabbMin(-5000, -5000, -5000);
			btVector3 worldAabbMax(5000, 5000, 5000);

			btDefaultCollisionConfiguration *collisionConfiguration = new btDefaultCollisionConfiguration();    // TODO: leaks
			btCollisionDispatcher *dispatcher = new btCollisionDispatcher(collisionConfiguration);
			btAxisSweep3 *broadphase = new btAxisSweep3(worldAabbMin, worldAabbMax);
			collisionWorld = new btCollisionWorld(dispatcher, broadphase, collisionConfiguration);
		}

		btMatrix3x3 basis;
		basis.setIdentity();
		collisionObject = new btCollisionObject();

		collisionObject->getWorldTransform().setBasis(basis);


		currentShape = new btBoxShape(btVector3(1, 1, 1));


		collisionObject->setCollisionShape(currentShape);
//        NSLog(@"add collision s %x %x", self,  collisionObject);

		collisionWorld->addCollisionObject(collisionObject);

		collisionAlgorithms = [[NSMutableDictionary alloc] init];
	}

	return self;
}

- (void)setCollisionShapeSphere:(vector3f)extent atPosition:(vector3f)_position
{
	btVector3 pos = btVector3(_position[0], _position[1], _position[2]);
	btScalar rad = btScalar(1.0);

	btMultiSphereShape *multiSphere = new btMultiSphereShape(&pos, &rad, 1);

	multiSphere->setLocalScaling(btVector3(extent[0], extent[1], extent[2]));

	collisionObject->setCollisionShape(multiSphere);

	delete currentShape;
	currentShape = multiSphere;
}

- (void)setCollisionShapeSphere:(vector3f)extent
{
	[self setCollisionShapeSphere:extent atPosition:vector3f(0.0f, 0.0f, 0.0f)];
}

- (void)setCollisionShapeBox:(vector3f)extent
{
	btBoxShape *box = new btBoxShape(btVector3(extent[0], extent[1], extent[2]));

	collisionObject->setCollisionShape(box);


	delete currentShape;
	currentShape = box;
}

- (void)resetState
{
	for (NSValue *v in [collisionAlgorithms allValues])
	{
		btCollisionAlgorithm *pAlgorithm = (btCollisionAlgorithm *) [v pointerValue];
		pAlgorithm->~btCollisionAlgorithm();
		collisionWorld->getDispatcher()->freeCollisionAlgorithm(pAlgorithm);
	}
	[collisionAlgorithms removeAllObjects];
}

- (void)dealloc
{
//	NSLog(@" dealloc s %x %x", self,  collisionObject);

	collisionWorld->removeCollisionObject(collisionObject);
	delete currentShape;
	delete collisionObject;

	[self resetState];

	[collisionAlgorithms release];
	collisionAlgorithms = nil;

	[super dealloc];
}

//- (void)renderNode
//{ // dont forget to disable deallocation if not in debug
//	if (globalInfo.renderpass & kRenderPassSetMaterial)
//	{
//		myColor(color[0], color[1], color[2], color[3]);
//		myMaterialSpecular(specularColor.data());
//		myMaterialShininess(shininess);
//	}
//	myClientStateVTN(kNeedDisabled, kNeedDisabled, kNeedDisabled);
//	glBegin(GL_TRIANGLES);
//	uint32_t i;
//	for (i = 0; i < octree_collision->rootnode.faceCount; i++)
//	{
//		uint16_t *f = (uint16_t *) _FACE_NUM(octree_collision, i);
//		float *v1 = (float *) _VERTEX_NUM(octree_collision, *f);
//		float *v2 = (float *) _VERTEX_NUM(octree_collision, *(f+1));
//		float *v3 = (float *) _VERTEX_NUM(octree_collision, *(f+2));
//
//		glNormal3f(*(v1+3), *(v1+4), *(v1+5));
//		glVertex3f(*v1, *(v1+1), *(v1+2));
//
//		glNormal3f(*(v2+3), *(v2+4), *(v2+5));
//		glVertex3f(*v2, *(v2+1), *(v2+2));
//
//		glNormal3f(*(v3+3), *(v3+4), *(v3+5));
//		glVertex3f(*v3, *(v3+1), *(v3+2));
//	}
//	glEnd();
//
//	globalInfo.drawCalls++;
//}

- (vector3f)intersectWithLineStart:(vector3f)startPoint end:(vector3f)endPoint
{
	btVector3 rayFrom = btVector3(startPoint[0], startPoint[1], startPoint[2]);
	btVector3 rayTo = btVector3(endPoint[0], endPoint[1], endPoint[2]);
	btCollisionWorld::ClosestRayResultCallback resultCallback(rayFrom, rayTo);
	btConvexCast::CastResult rayResult;
	btTransform rayFromTrans;
	btTransform rayToTrans;
	btQuaternion q;
	btVector3 aabbMin, aabbMax;
	btScalar hitLambda = 1.f;
	btVector3 hitNormal;


	rayFromTrans.setIdentity();
	rayFromTrans.setOrigin(rayFrom);
	rayToTrans.setIdentity();
	rayToTrans.setOrigin(rayTo);


	q.setEuler(cml::rad(rotation[1]), cml::rad(rotation[0]), cml::rad(rotation[2]));
	collisionObject->getWorldTransform().setRotation(q);
	collisionObject->getWorldTransform().setOrigin(btVector3(position[0], position[1], position[2]));
	collisionObject->getCollisionShape()->getAabb(collisionObject->getWorldTransform(), aabbMin, aabbMax);


	if (btRayAabb(rayFrom, rayTo, aabbMin, aabbMax, hitLambda, hitNormal))
	{
		btCollisionWorld::rayTestSingle(rayFromTrans, rayToTrans, collisionObject, collisionObject->getCollisionShape(), collisionObject->getWorldTransform(), resultCallback);

		if (resultCallback.hasHit())
			return vector3f(resultCallback.m_hitPointWorld[0], resultCallback.m_hitPointWorld[1], resultCallback.m_hitPointWorld[2]);
	}

	return vector3f(FLT_MAX, FLT_MAX, FLT_MAX);
}

- (TriangleIntersectionInfo)intersectWithNode:(SceneNode <Collideable> *)otherNode
{
	TriangleIntersectionInfo tif;
	tif.intersects = NO;



	btCollisionObject *otherCollisionObject = [otherNode collisionObject];
	btQuaternion q;
	q.setEuler(cml::rad(rotation[1]), cml::rad(rotation[0]), cml::rad(rotation[2]));
	collisionObject->getWorldTransform().setRotation(q);
	collisionObject->getWorldTransform().setOrigin(btVector3(position[0], position[1], position[2]));

	vector3f orot = [otherNode rotation], opot = [otherNode position];
	q.setEuler(cml::rad(orot[1]), cml::rad(orot[0]), cml::rad(orot[2]));
	otherCollisionObject->getWorldTransform().setRotation(q);
	otherCollisionObject->getWorldTransform().setOrigin(btVector3(opot[0], opot[1], opot[2]));

	btCollisionAlgorithm *pAlgorithm;
//#ifndef WIN32
	NSValue *v = [collisionAlgorithms objectForKey:$stringf(@"%p", otherNode)];
	if (v)
		pAlgorithm = (btCollisionAlgorithm *) [v pointerValue];
	else
	{
		assert(otherCollisionObject && collisionObject);
		pAlgorithm = collisionWorld->getDispatcher()->findAlgorithm(otherCollisionObject, collisionObject);
		[collisionAlgorithms setObject:[NSValue valueWithPointer:pAlgorithm] forKey:$stringf(@"%p", otherNode)];
	}
//#else
//    pAlgorithm = collisionWorld->getDispatcher()->findAlgorithm(otherCollisionObject, collisionObject);
//#endif

	btManifoldResult oManifoldResult(otherCollisionObject, collisionObject);
	pAlgorithm->processCollision(otherCollisionObject, collisionObject, collisionWorld->getDispatchInfo(), &oManifoldResult);
	btPersistentManifold *contactManifold = oManifoldResult.getPersistentManifold();

	if (contactManifold == NULL)
	{
		//	pAlgorithm->~btCollisionAlgorithm();
		return tif;
	}

	int numContacts = contactManifold->getNumContacts();
	for (int j = 0; j < numContacts; j++)
	{
		btManifoldPoint& pt = contactManifold->getContactPoint(j);

		//		btVector3 ptA = pt.getPositionWorldOnA();
		//		btVector3 ptB = pt.getPositionWorldOnB();
		//		btVector3 n = pt.m_normalWorldOnB;
		//
		//		NSLog(@"A %f %f %f", ptA.getX(), ptA.getY(), ptA.getZ());
		//		NSLog(@"B %f %f %f", ptB.getX(), ptB.getY(), ptB.getZ());
		//		NSLog(@"N %f %f %f", n.getX(), n.getY(), n.getZ());
		//
		//		NSLog(@"contact s %f", pt.getDistance());

		//
		//		matrix33f_c rm, orm;
		//		TriangleIntersectionInfo tif2;
		//
		//		matrix_rotation_euler(rm, rad(rotation[0]), rad(rotation[1]), rad(rotation[2]), euler_order_xyz);
		//		matrix_rotation_euler(orm, rad([otherMesh rotation][0]), rad([otherMesh rotation][1]), rad([otherMesh rotation][2]), euler_order_xyz);
		//
		//		tif2.intersects = intersectOctreeNodeWithOctreeNode(octree_collision, 0, position, rm, otherMesh->octree_collision, 0, [otherMesh position], orm, &tif2);
		//		vector3f normal = unit_cross(tif2.v1 - tif2.v2, tif2.v1 - tif2.v3);
		//		cout << normal << endl;
		//		normal = unit_cross(tif2.o1 - tif2.o2, tif2.o1 - tif2.o3);
		//		cout << normal << endl;

		if (pt.getDistance() < 0.00f)
		{
			btVector3 ptB = pt.getPositionWorldOnB();

			tif.intersects = YES;
			tif.depth = -pt.getDistance();
			tif.point = vector3f(ptB.getX(), ptB.getY(), ptB.getZ());
			tif.normal = vector3f(pt.m_normalWorldOnB.getX(), pt.m_normalWorldOnB.getY(), pt.m_normalWorldOnB.getZ());


			//	pAlgorithm->~btCollisionAlgorithm();
			return tif;
		}
	}

	//pAlgorithm->~btCollisionAlgorithm();
	return tif;
}

- (BOOL)intersectsWithNode:(SceneNode <Collideable> *)otherNode
{
	TriangleIntersectionInfo tif = [self intersectWithNode:otherNode];
	return tif.intersects;
}
@end
