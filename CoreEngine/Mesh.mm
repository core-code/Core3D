//
//
//  Mesh.m
//  Core3D
//
//  Created by CoreCode on 16.11.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


#import "Core3D.h"


#define RECURSION_THRESHOLD 1000
#undef glEnableVertexAttribArray
#undef glDisableVertexAttribArray
#define MAGIC_UNTEXTURED 0x6D616C62
#define MAGIC_TEXTURED 0xDEADBEEF
#define BUFFER_STRIDE ((octree->magicWord == MAGIC_UNTEXTURED) ? 6 : 8)

GLfloat frustum[6][4];
uint16_t _visibleNodeStackTop;

static void vfcTestOctreeNode(struct octree_struct *octree, uint16_t *visibleNodeStack, uint32_t nodeNum);
static void vfcTestOctreeNodePVS(struct octree_struct *octree, uint16_t *visibleNodeStack, uint32_t nodeNum, bool potentiallyVisible, bool *PVS);

@implementation Mesh


@synthesize octree, color, specularColor, visibleNodeStack, visibleNodeStackTop, shininess, doubleSided, texture, hasTransparency, pvsCells, contributionCullingDistance, srcBlend, dstBlend, dontDepthtest;

+ (struct octree_struct *)_loadOctreeFromFile:(NSURL *)file
{
	octree_struct *_octree;
	FILE *f;
	NSString *p = [file path];

#ifdef WIN32
	if ([p hasPrefix:@"/"]) p = [p substringFromIndex:1];
#endif
	f = fopen([p UTF8String], "rb");

	assert(f);

	if ([[[file path] pathExtension] isEqualToString:@"octree"])
	{
		unsigned long fileSize;
		size_t result;


		fseek(f, 0, SEEK_END);
		fileSize = (unsigned long) ftell(f);
		rewind(f);


		_octree = (octree_struct *) malloc(fileSize);     // TODO: mmap instead allows swapping on iphone
		assert(_octree);

		result = fread(_octree, 1, fileSize, f);
		assert(result == fileSize);
	}
	else if ([[[file path] pathExtension] isEqualToString:@"snz"])
	{
		// uint64_t micro = GetNanoseconds() / 1000;

		_octree = (octree_struct *) UncompressedBufferFromSNZFile(f);


		// uint64_t post = GetNanoseconds() / 1000;

		// NSLog(@"decompressing %@ took %f", [file lastPathComponent], (post-micro) / 1000.0);
	}
	else
		fatal("Error: the file named %s doesn't seem to be a valid octree", [[file absoluteString] UTF8String]);

	fclose(f);

	if ((_octree->magicWord != MAGIC_UNTEXTURED) && (_octree->magicWord != MAGIC_TEXTURED))
		fatal("Error: the file named %s doesn't seem to be a valid octree", [[file absoluteString] UTF8String]);

	return _octree;
}

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithOctreeNamed:(NSString *)_name
{
	NSString *octreeURL = [[NSBundle mainBundle] pathForResource:_name ofType:@"octree"];
	NSString *snzURL = [[NSBundle mainBundle] pathForResource:_name ofType:@"octree.snz"];

	if (!octreeURL && !snzURL)
		fatal("Error: there is no octree named: %s", [_name UTF8String]);

	return [self initWithOctree:(octreeURL ? [NSURL fileURLWithPath:octreeURL] : [NSURL fileURLWithPath:snzURL]) andName:_name];
}

- (id)initWithOctreeNamed:(NSString *)_name andTexureQuality:(NSNumber *)texQuality
{
	_texQuality = texQuality;
	return [self initWithOctreeNamed:_name];
}

- (id)initWithOctree:(NSURL *)file andName:(NSString *)_name andTexureQuality:(NSNumber *)texQuality
{
	_texQuality = texQuality;
	return [self initWithOctree:file andName:_name];
}

- (id)initWithOctree:(NSURL *)file andName:(NSString *)_name
{
	if ((self = [super init]))
	{

		name = [[NSString alloc] initWithString:_name];
		octree = [Mesh _loadOctreeFromFile:file];

		NSData *pvsData = [NSData dataWithContentsOfURL:[[[file URLByDeletingPathExtension] URLByDeletingPathExtension] URLByAppendingPathExtension:@"pvs"]];

		if (pvsData)
		{
			pvsCells = (uint16_t *) malloc([pvsData length]);
			[pvsData getBytes:pvsCells length:[pvsData length]];
			// NSLog(@"mesh %@ gets pvs!", name);
		}

		contributionCullingDistance = 99999.9f;
		shininess = 30.0f;
		doubleSided = FALSE;
		visible = YES;
		srcBlend = GL_SRC_ALPHA;
		dstBlend = GL_ONE_MINUS_SRC_ALPHA;

		[self setColor:vector4f(1.0f, 1.0f, 1.0f, 1.0f)];
		[self setSpecularColor:vector4f(1.0f, 1.0f, 1.0f, 1.0f)];

#ifdef TARGET_OS_IPHONE
		if (octree->vertexCount > 0xFFFF)
			fatal("Error: only 0xFFFF vertices per object supported on iOS %s %i", [name UTF8String], octree->vertexCount);
#endif

		int indexSize = octree->vertexCount > 0xFFFF ? sizeof(uint32_t) : sizeof(uint16_t);

		vbo = [[VBO alloc] init];

		[vbo setIndexBuffer:OFFSET_FACES withSize:octree->rootnode.faceCount * 3 * indexSize];
		[vbo setVertexBuffer:OFFSET_VERTICES withSize:octree->vertexCount * BUFFER_STRIDE * sizeof(float)];
		[vbo setVertexAttribPointer:(const GLvoid *) 0
		                   forIndex:VERTEX_ARRAY withSize:3 withType:GL_FLOAT shouldNormalize:GL_FALSE withStride:BUFFER_STRIDE * sizeof(float)];
		[vbo setVertexAttribPointer:(const GLfloat *) (sizeof(float) * 3)
		                   forIndex:NORMAL_ARRAY withSize:3 withType:GL_FLOAT shouldNormalize:GL_FALSE withStride:BUFFER_STRIDE * sizeof(float)];
		if (octree->magicWord != MAGIC_UNTEXTURED)
			[vbo setVertexAttribPointer:(const GLfloat *) (sizeof(float) * 6)
			                   forIndex:TEXTURE_COORD_ARRAY withSize:2 withType:GL_FLOAT shouldNormalize:GL_FALSE withStride:BUFFER_STRIDE * sizeof(float)];
		[vbo load];

		if (octree->magicWord != MAGIC_UNTEXTURED)
		{
			texture = [Texture newTextureNamed:name];

			if (!texture)
			{
				NSURL *p = [[[file URLByDeletingPathExtension] URLByDeletingPathExtension] URLByAppendingPathExtension:@"png"];
				NSURL *d = [[[file URLByDeletingPathExtension] URLByDeletingPathExtension] URLByAppendingPathExtension:@"dds"];
				if ([[NSFileManager defaultManager] fileExistsAtPath:[p path]])
					texture = [(Texture *) [Texture alloc] initWithContentsOfURL:p];
				else if ([[NSFileManager defaultManager] fileExistsAtPath:[d path]])
					texture = [(Texture *) [Texture alloc] initWithContentsOfURL:d];
			}

			if (_texQuality)
				[texture setQuality:[_texQuality shortValue]];
			else
				[texture setQuality:$defaulti(kTextureQualityKey)];

			[texture load];
		}
		else
		{
			NSDebugLog(@"Info: %@ is an untextured mesh", _name);
		}

		assert([self size].length() > 0.0001);
		
		visibleNodeStack = (uint16_t *) calloc(1, octree->nodeCount * sizeof(uint16_t));

		[self cleanup];
	}

	return self;
}

- (vector3f)center
{
	struct octree_node const *const n1 = (struct octree_node *) NODE_NUM(0);
	vector3f extent = vector3f(n1->aabbExtentX, n1->aabbExtentY, n1->aabbExtentZ);
	vector3f origin = vector3f(n1->aabbOriginX, n1->aabbOriginY, n1->aabbOriginZ);

	return vector3f(origin + extent / 2.0);
}

- (vector3f)size
{
	struct octree_node const *const n1 = (struct octree_node *) NODE_NUM(0);
	vector3f extent = vector3f(n1->aabbExtentX, n1->aabbExtentY, n1->aabbExtentZ);

	return vector3f(extent / 2.0);
}

- (float)radius
{
	struct octree_node const *const n1 = (struct octree_node *) NODE_NUM(0);
	vector3f extent = vector3f(n1->aabbExtentX, n1->aabbExtentY, n1->aabbExtentZ);
	return extent.length() / 2.0f;
}

- (void)cleanup
{
#ifndef DEBUG
	octree = (octree_struct *) realloc(octree, (sizeof(struct octree_struct) + (octree->nodeCount - 1) * sizeof(struct octree_node)));
#endif
}

- (id)copyWithZone:(NSZone *)zone
{
	fatal("copying meshes currently not advised");
	Mesh *octreeCopy = (Mesh *) NSCopyObject(self, 0, zone);

	octreeCopy->name = [[NSString alloc] initWithString:name];
	octreeCopy->visibleNodeStack = (uint16_t *) calloc(1, octree->nodeCount * sizeof(uint16_t));

	return octreeCopy;
}

- (NSString *)description
{
	NSMutableString *desc = [NSMutableString stringWithString:@"Mesh: "];

	[desc appendFormat:@"%@ (%p)\n Nodes/Vertices/Faces: %i / %i / %i\n", name, (void *) self, octree->nodeCount, octree->vertexCount, octree->rootnode.faceCount];
	struct octree_node *n = (struct octree_node *) NODE_NUM(0);
	[desc appendFormat:@" RootNode: firstFace: %i faceCount:%i\n  origin:%f %f %f\n  extent: %f %f %f\n  children: %i %i %i %i %i %i %i %i\n", n->firstFace, n->faceCount, n->aabbOriginX, n->aabbOriginY, n->aabbOriginZ, n->aabbExtentX, n->aabbExtentY, n->aabbExtentZ, n->childIndex1, n->childIndex2, n->childIndex3, n->childIndex4, n->childIndex5, n->childIndex6, n->childIndex7, n->childIndex8];


	if (0)
	{
		[desc appendFormat:@"NodeOffset:%p\n", (void *) OFFSET_NODES];
		[desc appendFormat:@"VertexOffset:%p\n", (void *) OFFSET_VERTICES];
		[desc appendFormat:@"FaceOffset:%p\n", (void *) OFFSET_FACES];

		uint32_t i;
		[desc appendString:@"Nodes:\n"];
		for (i = 0; i < octree->nodeCount; i++)
		{
			struct octree_node *_n = (struct octree_node *) NODE_NUM(i);
			[desc appendFormat:@"%i: firstFace: %i faceCount:%i origin:%f %f %f extent: %f %f %f children: %i %i %i %i %i %i %i %i\n", i, _n->firstFace, _n->faceCount, _n->aabbOriginX, _n->aabbOriginY, _n->aabbOriginZ, _n->aabbExtentX, _n->aabbExtentY, _n->aabbExtentZ, _n->childIndex1, _n->childIndex2, _n->childIndex3, _n->childIndex4, _n->childIndex5, _n->childIndex6, _n->childIndex7, _n->childIndex8];
		}
#ifdef DEBUG
		[desc appendString:@"\nVertices:\n"];
		for (i = 0; i < octree->vertexCount; i++)
		{
			float *v = (float *) VERTEX_NUM(i);
			if (octree->magicWord == MAGIC_UNTEXTURED)
				[desc appendFormat:@"%i: x: %f y: %f z: %f nx: %f ny: %f nz: %f\n", i, *v, *(v + 1), *(v + 2), *(v + 3), *(v + 4), *(v + 5)];
			else
				[desc appendFormat:@"%i: x: %f y: %f z: %f nx: %f ny: %f nz: %f  tx: %f ty: %f tz: %f\n", i, *v, *(v + 1), *(v + 2), *(v + 3), *(v + 4), *(v + 5), *(v + 6), *(v + 7), *(v + 8)];
		}
		[desc appendString:@"\nFaces:\n"];
		for (i = 0; i < octree->rootnode.faceCount; i++)
		{
			uint16_t *f = (uint16_t *) FACE_NUM(i);

			[desc appendFormat:@"%i: v1: %u v2: %u v3: %u\n", i, *f, *(f + 1), *(f + 2)];
		}
#endif
	}

	//return [NSString stringWithString:[[super description] stringByAppendingString:desc]];
	return [NSString stringWithString:desc];
}

- (void)renderNode
{

	renderPassEnum renderSettings = [currentRenderPass settings];

	if (!globalSettings.disableCulling && (renderSettings & kRenderPassUpdateCulling)) // perform culling
	{
		visible = TRUE;

		if (contributionCullingDistance < 10000.0f
				&& matrix_get_translation([currentCamera modelViewMatrix]).length() > contributionCullingDistance) // contribution culling
		{
			visible = FALSE;
		}

		if (visible) // view frustum and occlusion culling
		{
			_visibleNodeStackTop = 0;

			extract_frustum_planes([currentCamera modelViewMatrix],
					[currentCamera projectionMatrix],
					frustum, cml::z_clip_neg_one, false);

			if (pvsCells && renderSettings & kRenderPassUsePVS && currentRenderPass.currentPVSCell >= 0)
			{
				bool nodes[octree->nodeCount];
				uint16_t startIndex = pvsCells[1 + currentRenderPass.currentPVSCell];
				uint16_t stopIndex = pvsCells[1 + currentRenderPass.currentPVSCell + 1];


				memset(nodes, 0, octree->nodeCount * sizeof(bool));



				for (uint16_t index = startIndex; index < stopIndex; index++)
					nodes[pvsCells[1 + globalInfo.pvsCells + 1 + index]] = 1;


				vfcTestOctreeNodePVS(octree, visibleNodeStack, 0, nodes[0], &nodes[0]);
			}
			else
				vfcTestOctreeNode(octree, visibleNodeStack, 0);


			visibleNodeStackTop = _visibleNodeStackTop;

			if (!visibleNodeStackTop)
			{
				visible = FALSE;
			}
		}
	}

	if (!visible)
	{
		// TODO: we really gotta find a more clever system that allows us to do culling once even for nodes that are attached *at multiple positions* for multiple passes, call update: cull: render:

		return;
	}


#ifndef GL_ES_VERSION_2_0
    #ifdef DEBUG
	if (globalSettings.doWireframe)
		glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
    #endif
#endif

	if (renderSettings & kRenderPassSetMaterial)
	{
		globalMaterial.color = color;
		globalMaterial.specular = specularColor;
		globalMaterial.shininess = shininess;

		if (hasTransparency)
			myBlendFunc(srcBlend, dstBlend);
	}


	myEnableBlendParticleCullDepthtestDepthwrite(hasTransparency && (renderSettings & kRenderPassSetMaterial), NO, !(doubleSided && (renderSettings & kRenderPassSetMaterial)), !dontDepthtest, YES);
	[vbo bind];

	if ((octree->magicWord != MAGIC_UNTEXTURED) && // textured
			(renderSettings & kRenderPassUseTexture) && // and should use texture
			(!globalSettings.disableTex)) // and texture not disabled
		[texture bind];


	assert(currentShader);
	[currentShader prepare];


	if (globalSettings.disableCulling) // no view frustum culling, render everthing with a single call
	{
#ifndef TARGET_OS_IPHONE
		if 	(octree->vertexCount > 0xFFFF)
		{	glDrawElements(GL_TRIANGLES, octree->rootnode.faceCount * 3, GL_UNSIGNED_INT, (const GLuint *) 0); }
		else
#endif
		{glDrawElements(GL_TRIANGLES, octree->rootnode.faceCount * 3, GL_UNSIGNED_SHORT, (const GLushort *) 0);}

		globalInfo.renderedFaces += octree->rootnode.faceCount;
		globalInfo.visitedNodes++;
		globalInfo.drawCalls++;
		/*DRAW_CALL*/
	}
	else
	{
		uint16_t i;
		for (i = 0; i < visibleNodeStackTop;)
		{
			struct octree_node *n = (struct octree_node *) NODE_NUM(visibleNodeStack[i]);
			uint32_t fc = n->faceCount;
			uint32_t ff = n->firstFace;
			uint16_t v = i + 1;
			while (v < visibleNodeStackTop)
			{
				struct octree_node *nn = (struct octree_node *) NODE_NUM(visibleNodeStack[v]);

				if (nn->firstFace != n->firstFace + n->faceCount)    // TODO: allow for some draw call reduction at the expense of drawing invisible stuff
					break;


				fc += nn->faceCount;
				n = nn;
				v++;
			}

			i = v;
#ifndef TARGET_OS_IPHONE
            if 	(octree->vertexCount > 0xFFFF)
            {	glDrawElements(GL_TRIANGLES, fc * 3, GL_UNSIGNED_INT, (const GLuint *) 0 + (ff * 3)); }
            else
#endif
			{glDrawElements(GL_TRIANGLES, fc * 3, GL_UNSIGNED_SHORT, (const GLushort *) 0 + (ff * 3));}

			globalInfo.drawCalls++;
			/*DRAW_CALL*/
			globalInfo.renderedFaces += n->faceCount;
		}
	}


#ifndef GL_ES_VERSION_2_0
#ifdef DEBUG
	if (globalSettings.doWireframe)
		glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
#endif
#endif
}

// editor support
- (void)setValue:(id)value forKey:(NSString *)key
{
	if ([key isEqualToString:@"color"])
	{
		vector4f v;
		[value getValue:&v];
		[self setColor:v];
	}
	else if ([key isEqualToString:@"specularColor"])
	{
		vector4f v;
		[value getValue:&v];
		[self setSpecularColor:v];
	}
	else [super setValue:value forKey:key];
}

- (void)dealloc
{
	//	NSLog(@"dealloc mesh %@", [self description]);
	free(pvsCells);
	free(octree);
	free(visibleNodeStack);
	[texture release];

	[vbo release];

	[super dealloc];
}
@end

static void vfcTestOctreeNode(struct octree_struct *octree, uint16_t *visibleNodeStack, uint32_t nodeNum) // TODO: optimization: VFC coherence (http://www.cescg.org/CESCG-2002/DSykoraJJelinek/index.html)
{
	struct octree_node const *const n = (struct octree_node *) NODE_NUM(nodeNum);
	char result;

	globalInfo.visitedNodes++;

	if (n->faceCount == 0)
		return;

	result = AABoxInFrustum((const float (*)[4]) frustum, n->aabbOriginX, n->aabbOriginY, n->aabbOriginZ, n->aabbExtentX, n->aabbExtentY, n->aabbExtentZ);
	if (result == kIntersecting)
	{
		if ((n->childIndex1 == 0xFFFF) || (n->faceCount < RECURSION_THRESHOLD))
			visibleNodeStack[_visibleNodeStackTop++] = (uint16_t) nodeNum;
		else
		{
			vfcTestOctreeNode(octree, visibleNodeStack, n->childIndex1);
			vfcTestOctreeNode(octree, visibleNodeStack, n->childIndex2);
			vfcTestOctreeNode(octree, visibleNodeStack, n->childIndex3);
			vfcTestOctreeNode(octree, visibleNodeStack, n->childIndex4);
			vfcTestOctreeNode(octree, visibleNodeStack, n->childIndex5);
			vfcTestOctreeNode(octree, visibleNodeStack, n->childIndex6);
			vfcTestOctreeNode(octree, visibleNodeStack, n->childIndex7);
			vfcTestOctreeNode(octree, visibleNodeStack, n->childIndex8);
		}
	}
	else if (result == kInside)
		visibleNodeStack[_visibleNodeStackTop++] = (uint16_t) nodeNum;
}

static void vfcTestOctreeNodePVS(struct octree_struct *octree, uint16_t *visibleNodeStack, uint32_t nodeNum, bool potentiallyVisible, bool *PVS)
{
	struct octree_node const *const n = (struct octree_node *) NODE_NUM(nodeNum);
	char result;

	globalInfo.visitedNodes++;

	if (n->faceCount == 0)
		return;

	result = AABoxInFrustum((const float (*)[4]) frustum, n->aabbOriginX, n->aabbOriginY, n->aabbOriginZ, n->aabbExtentX, n->aabbExtentY, n->aabbExtentZ);

	if (result == kInside && potentiallyVisible)
		visibleNodeStack[_visibleNodeStackTop++] = (uint16_t) nodeNum;
	else if (result == kIntersecting || (result == kInside && !potentiallyVisible))
	{
		if (n->childIndex1 == 0xFFFF)
		{
			if (potentiallyVisible)
				visibleNodeStack[_visibleNodeStackTop++] = (uint16_t) nodeNum;
		}
		else
		{
			vfcTestOctreeNodePVS(octree, visibleNodeStack, n->childIndex1, potentiallyVisible ? YES : PVS[n->childIndex1], PVS);
			vfcTestOctreeNodePVS(octree, visibleNodeStack, n->childIndex2, potentiallyVisible ? YES : PVS[n->childIndex2], PVS);
			vfcTestOctreeNodePVS(octree, visibleNodeStack, n->childIndex3, potentiallyVisible ? YES : PVS[n->childIndex3], PVS);
			vfcTestOctreeNodePVS(octree, visibleNodeStack, n->childIndex4, potentiallyVisible ? YES : PVS[n->childIndex4], PVS);
			vfcTestOctreeNodePVS(octree, visibleNodeStack, n->childIndex5, potentiallyVisible ? YES : PVS[n->childIndex5], PVS);
			vfcTestOctreeNodePVS(octree, visibleNodeStack, n->childIndex6, potentiallyVisible ? YES : PVS[n->childIndex6], PVS);
			vfcTestOctreeNodePVS(octree, visibleNodeStack, n->childIndex7, potentiallyVisible ? YES : PVS[n->childIndex7], PVS);
			vfcTestOctreeNodePVS(octree, visibleNodeStack, n->childIndex8, potentiallyVisible ? YES : PVS[n->childIndex8], PVS);
		}
	}
}