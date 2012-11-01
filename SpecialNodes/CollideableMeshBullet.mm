//
//  CollideableMeshBullet.m
//  Core3D
//
//  Created by CoreCode on 10.07.09.
//  Copyright 2009 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


#import "Core3D.h"
#import "CollideableMeshBullet.h"


btCollisionWorld *collisionWorld = 0;

extern BOOL intersectOctreeNodeWithLine(struct octree_struct *octree, int nodeNum, const vector3f startPoint, const vector3f endPoint, float intersectionPoint[3]);
extern BOOL intersectOctreeNodeWithOctreeNode(struct octree_struct *octree, int nodeNum, const vector3f position, const matrix33f_c orthogonalBase, struct octree_struct *otherOctree, int otherNodeNum, const vector3f otherPosition, const matrix33f_c otherOrthogonalBase, TriangleIntersectionInfo *intersectionInfo);

@implementation CollideableMeshBullet

@synthesize collisionObject;

- (id)initWithOctree:(NSURL *)file andName:(NSString *)_name
{
	if ((self = [super initWithOctree:file andName:_name]))
	{
		NSString *octreeURL = [[NSBundle mainBundle] pathForResource:[_name stringByAppendingString:@"_collision"] ofType:@"octree"];
		NSString *snzURL = [[NSBundle mainBundle] pathForResource:[_name stringByAppendingString:@"_collision"] ofType:@"octree.snz"];

		if (!octreeURL && !snzURL)
		{
			//		NSLog(@"Warning: there is no collision octree for collidable object: %@ %p", _name, self);

			octree_collision = octree;
		}
		else
		{
			octree_collision = [Mesh _loadOctreeFromFile:(octreeURL ? [NSURL fileURLWithPath:octreeURL] : [NSURL fileURLWithPath:snzURL])];


			if (octree_collision->magicWord != 0x6D616C62)
				NSLog(@"Notice: texcoords are superfluous for collision octree: %@", _name);

			[super cleanup];
		}

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

		currentShape = new btBoxShape(btVector3(1.0f, 1.0f, 1.0f));

		collisionObject->setCollisionShape(currentShape);

		//      NSLog(@"add collision m %x %x", self, collisionObject);
		collisionWorld->addCollisionObject(collisionObject);

		collisionAlgorithms = [[NSMutableDictionary alloc] init];
	}

	return self;
}

///////////// TODO: COPYING?

- (void)setCollisionShapeSphere:(vector3f)extent atPosition:(vector3f)_position
{
	btVector3 pos = btVector3(_position[0], _position[1], _position[2]);
	btScalar rad = btScalar(1.0);

	btMultiSphereShape *multiSphere = new btMultiSphereShape(&pos, &rad, 1);

	multiSphere->setLocalScaling(btVector3(extent[0], extent[1], extent[2]));

	collisionObject->setCollisionShape(multiSphere);

	delete currentShape;
	currentShape = multiSphere;

	[self cleanup];
}

- (void)setCollisionShapeFittingSphere
{
	vector3f aabbExtent = vector3f((octree_collision->rootnode.aabbExtentX), (octree_collision->rootnode.aabbExtentY), (octree_collision->rootnode.aabbExtentZ)) / 2.0;
	vector3f aabbOrigin = vector3f(octree_collision->rootnode.aabbOriginX, octree_collision->rootnode.aabbOriginY, octree_collision->rootnode.aabbOriginZ) + aabbExtent;

	[self setCollisionShapeSphere:aabbExtent atPosition:aabbOrigin];
}

- (void)setCollisionShapeSphere:(vector3f)extent
{
	vector3f aabbExtent = vector3f((octree_collision->rootnode.aabbExtentX), (octree_collision->rootnode.aabbExtentY), (octree_collision->rootnode.aabbExtentZ)) / 2.0;
	vector3f aabbOrigin = vector3f(octree_collision->rootnode.aabbOriginX, octree_collision->rootnode.aabbOriginY, octree_collision->rootnode.aabbOriginZ) + aabbExtent;

	[self setCollisionShapeSphere:extent atPosition:aabbOrigin];
}

- (void)setCollisionShapeBox:(vector3f)extent
{
	btBoxShape *box = new btBoxShape(btVector3(extent[0], extent[1], extent[2]));

	collisionObject->setCollisionShape(box);

	[self cleanup];

	delete currentShape;
	currentShape = box;
}

- (void)setCollisionShapeConvexHull:(BOOL)simplify
{
	btCollisionShape *hull = new btConvexHullShape((const btScalar *) _OFFSET_VERTICES(octree_collision), octree_collision->vertexCount);

	if (simplify)
	{
		btShapeHull *small_hull = new btShapeHull((btConvexHullShape *) hull);

		small_hull->buildHull(hull->getMargin());

		btConvexHullShape *simplifiedConvexShape = new btConvexHullShape((const btScalar *) small_hull->getVertexPointer(), small_hull->numVertices());

		//	simplifiedConvexShape->setLocalScaling(btVector3(btScalar(0.25), btScalar(4.0), btScalar(1.0)));

		collisionObject->setCollisionShape(simplifiedConvexShape);
	}
	else
	{
		//	hull->setLocalScaling(btVector3(btScalar(0.25), btScalar(4.0), btScalar(1.0)));

		collisionObject->setCollisionShape(hull);
	}

	[self cleanup];

	delete currentShape;
	currentShape = hull;
}

//#import "gim_math.h"
//#import "btGImpactShape.h"

- (void)setCollisionShapeTriangleMesh:(BOOL)gimpact // TODO: gimpact
{
	if (meshInterface)
		delete meshInterface;
	meshInterface = new btTriangleIndexVertexArray();
	btIndexedMesh part;


	part.m_vertexBase = (const unsigned char *) _OFFSET_VERTICES(octree_collision);
	part.m_vertexStride = (octree_collision->magicWord == 0x6D616C62) ? sizeof(float) * 6 : sizeof(float) * 8;
	part.m_numVertices = octree_collision->vertexCount;
	part.m_triangleIndexBase = (const unsigned char *) _OFFSET_FACES(octree_collision);
	part.m_numTriangles = octree_collision->rootnode.faceCount;
	part.m_triangleIndexStride = (octree_collision->vertexCount > 0xFFFF) ? sizeof(unsigned int) * 3 : sizeof(unsigned short) * 3;
	part.m_indexType = (octree_collision->vertexCount > 0xFFFF) ? PHY_INTEGER : PHY_SHORT;

	meshInterface->addIndexedMesh(part, part.m_indexType);

	btBvhTriangleMeshShape *trimeshShape = new btBvhTriangleMeshShape(meshInterface, true);
//	btGImpactMeshShape * trimeshShape = new btGImpactMeshShape(meshInterface);


	collisionObject->setCollisionShape(trimeshShape);

	delete currentShape;
	currentShape = trimeshShape;
}

- (void)cleanup
{
	if (octree != octree_collision)
	{
		free(octree_collision);
		octree_collision = NULL;
	}
	else
	{
		[super cleanup];
		octree_collision = octree;
	}
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
	//   NSLog(@"algo cache emptied %@ %p", [collisionAlgorithms description], self);
}

- (void)dealloc
{
	if ((octree != octree_collision) && (octree_collision != NULL))
		free(octree_collision);

	collisionWorld->removeCollisionObject(collisionObject);

	[self resetState];
	[collisionAlgorithms release];
	collisionAlgorithms = nil;

	delete meshInterface;
	delete currentShape;
	delete collisionObject;

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
//    /*DRAW_CALL*/
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
	{
		pAlgorithm = (btCollisionAlgorithm *) [v pointerValue];
		//NSLog(@"algo cached  %@ %p", [collisionAlgorithms description], self);
	}
	else
	{
		pAlgorithm = collisionWorld->getDispatcher()->findAlgorithm(otherCollisionObject, collisionObject);
		[collisionAlgorithms setObject:[NSValue valueWithPointer:pAlgorithm] forKey:$stringf(@"%p", otherNode)];
		//NSLog(@"algo created self %p", self);
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
//		NSLog(@"contact %f", pt.getDistance());

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

//	pAlgorithm->~btCollisionAlgorithm();
	return tif;
}

- (BOOL)intersectsWithNode:(SceneNode <Collideable> *)otherNode
{
	TriangleIntersectionInfo tif = [self intersectWithNode:otherNode];
	return tif.intersects;
}

//- (id)copyWithZone:(NSZone *)zone // TODO: fix crashes when deallocating copy'ed collidadeablemeshes rather by using ref counting for octrees
//{
//	Mesh *octreeCopy = [super copyWithZone:zone];
//
//	void *newBuffer = malloc(malloc_size(octree_collision));
//	memcpy(newBuffer, octree_collision, malloc_size(octree_collision));
//	octree_collision = (octree_struct *)newBuffer;
//
//	return octreeCopy;
//}
@end
