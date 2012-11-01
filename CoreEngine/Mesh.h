//
//  Mesh.h
//  Core3D
//
//  Created by CoreCode on 16.11.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

struct octree_node
{
	uint32_t firstFace;
	uint32_t faceCount;
	float aabbOriginX, aabbOriginY, aabbOriginZ;
	float aabbExtentX, aabbExtentY, aabbExtentZ;
	uint16_t childIndex1, childIndex2, childIndex3, childIndex4, childIndex5, childIndex6, childIndex7, childIndex8;
};

struct octree_struct // TODO: optimization: add optimized prefetch indices for glDrawRangeElements, convert to aabbCenter
{
	uint32_t magicWord;
	uint32_t nodeCount;
	uint32_t vertexCount;
	struct octree_node rootnode;
};

#define _OFFSET_NODES(oct)        ((char *)oct + sizeof(struct octree_struct) - sizeof(struct octree_node))
#define _OFFSET_VERTICES(oct)    (_OFFSET_NODES(oct) + oct->nodeCount * sizeof(struct octree_node))
#define _OFFSET_FACES(oct)        (_OFFSET_VERTICES(oct) + oct->vertexCount * ((oct->magicWord == 0x6D616C62) ? 6 : 8) * sizeof(float))
#define _NODE_NUM(oct, x)        (_OFFSET_NODES(oct) + (x) * sizeof(struct octree_node))
#define _VERTEX_NUM(oct, x)        (_OFFSET_VERTICES(oct) + (x) * ((oct->magicWord == 0x6D616C62) ? 6 : 8) * sizeof(float))
#define _FACE_NUM(oct, x)        (_OFFSET_FACES(oct) + (x) * 3 * sizeof(uint16_t))

#define OFFSET_NODES    (_OFFSET_NODES(octree))
#define OFFSET_VERTICES    (_OFFSET_VERTICES(octree))
#define OFFSET_FACES    (_OFFSET_FACES(octree))
#define NODE_NUM(x)        (_NODE_NUM(octree, x))
#define VERTEX_NUM(x)    (_VERTEX_NUM(octree, x))
#define FACE_NUM(x)        (_FACE_NUM(octree, x))


@interface Mesh : SceneNode
{
	BOOL visible;
	BOOL hasTransparency;
	struct octree_struct *octree;

	vector4f color, specularColor;
	float shininess;
	float contributionCullingDistance;
	BOOL doubleSided, dontDepthtest;

	uint16_t *pvsCells;
	uint16_t *visibleNodeStack;
	uint16_t visibleNodeStackTop;

	Texture *texture;
	NSNumber *_texQuality;

	VBO *vbo;

	GLenum srcBlend;
	GLenum dstBlend;
}

@property (assign, nonatomic) GLenum srcBlend;
@property (assign, nonatomic) GLenum dstBlend;
@property (readonly, nonatomic) struct octree_struct *octree;
@property (readonly, nonatomic) uint16_t *visibleNodeStack;
@property (readonly, nonatomic) uint16_t visibleNodeStackTop;

@property (assign, nonatomic) uint16_t *pvsCells;

@property (assign, nonatomic) BOOL hasTransparency;
@property (assign, nonatomic) vector4f color;
@property (assign, nonatomic) vector4f specularColor;
@property (assign, nonatomic) BOOL doubleSided;
@property (assign, nonatomic) BOOL dontDepthtest;
@property (assign, nonatomic) float shininess;
@property (assign, nonatomic) float contributionCullingDistance;
@property (nonatomic, retain) Texture *texture;

+ (struct octree_struct *)_loadOctreeFromFile:(NSURL *)file;
- (id)initWithOctreeNamed:(NSString *)_name;
- (id)initWithOctreeNamed:(NSString *)_name andTexureQuality:(NSNumber *)texQuality;
- (id)initWithOctree:(NSURL *)file andName:(NSString *)_name;
- (id)initWithOctree:(NSURL *)file andName:(NSString *)_name andTexureQuality:(NSNumber *)texQuality;
- (void)cleanup;

- (vector3f)center;
- (vector3f)size;
- (float)radius;
@end
