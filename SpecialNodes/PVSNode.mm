//
//  PVSNode.mm
//  Core3D
//
//  Created by CoreCode on 13.12.09.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


#import "Game.h"
#import "Core3D.h"
#import "PVSNode.h"

#include <map>


#define BYTE1(v)                ((uint8_t) (v))
#define BYTE2(v)                ((uint8_t) (((uint32_t) (v)) >> 8))
#define BYTE3(v)                ((uint8_t) (((uint32_t) (v)) >> 16))
#define BYTE4(v)                ((uint8_t) (((uint32_t) (v)) >> 24))

@implementation PVSNode

- (id)initWithObjectArray:(NSArray *)_objects //nodeMesh:(Mesh *)_nodeMesh samplesPerCell:(uint16_t)_samplesPerCell
{
	if ((self = [super init]))
	{
		NSMutableArray *tmpObj = [[NSMutableArray alloc] init];

		for (id obj in _objects)
		{
			if ([obj isKindOfClass:[Mesh class]])
				[tmpObj addObject:obj];
		}

		objects = [tmpObj copy];
		[tmpObj release];
		//		nodeMesh = _nodeMesh;
		//		samplesPerCell = _samplesPerCell;
	}
	return self;
}

/*

- (void)render // override render instead of implementing renderNode
{
	if (globalInfo.frame == 1)
	{
		GLuint fboColorTexture, fboDepthTexture, fbo, objNum, pboReadback[6];

        Shader *shader = [Shader newShaderNamed:@"color" withTexcoordsBound:YES andNormalsBound:YES];

		[shader bind];

#warning PVS gen broken
		glGenTextures(1, &fboDepthTexture);
		glBindTexture(GL_TEXTURE_2D, fboDepthTexture);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_DEPTH_TEXTURE_MODE, GL_LUMINANCE );
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_NONE );
		glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT24, 1024, 1024, 0, GL_DEPTH_COMPONENT, GL_UNSIGNED_BYTE, NULL);

		glGenTextures(1, &fboColorTexture);
		glBindTexture(GL_TEXTURE_2D, fboColorTexture);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1024, 1024, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, NULL);

		glGenFramebuffersEXT(1, &fbo);
		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fbo);

		glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, fboColorTexture, 0);
		glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_TEXTURE_2D, fboDepthTexture, 0);

		if (glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT) != GL_FRAMEBUFFER_COMPLETE_EXT)
			fatal("Error: couldn't setup FBO %04x", (unsigned int)glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT));


		glGenBuffers(6, &pboReadback[0]);
		for (int pbo = 0; pbo < 6; pbo ++)
		{
			glBindBuffer(GL_PIXEL_PACK_BUFFER, pboReadback[pbo]);
			glBufferData(GL_PIXEL_PACK_BUFFER, 1024 * 1024 * 4, 0, GL_STREAM_READ);
			glBindBuffer(GL_PIXEL_PACK_BUFFER, 0);
		}

		map<uint32_t, uint32_t>		visibleNodes;


		glPushAttrib(GL_VIEWPORT_BIT);
		myViewport(0, 0, 1024, 1024);
		glPushMatrix();
		glLoadIdentity();


		Camera *savedCam = currentCamera;
		Camera *ourCam = [[[Camera alloc] init] autorelease];
		currentCamera = ourCam;
		[ourCam setFov:90];
		[ourCam setNearPlane:1];
		[ourCam setFarPlane:14000];
		[ourCam reshape:CGSizeMake(PVS_RESOLUTION, PVS_RESOLUTION)];

		float rots[6][3] = {{0, 0, 0}, {0, 90, 0}, {0, 180, 0}, {0, 270, 0}, {90, 0, 0}, {-90, 0, 0}};
		float cameraOffset[3][3] = {{0, 3.75, 6}, {0, 1, 2.25}, {0, 0, -1}};


		int32_t i;

		//		for (i = 0; i < [nodeMesh octree]->nodeCount; i++)
		//		{
		//			struct octree_node *n = (struct octree_node *) _NODE_NUM([nodeMesh octree], i);
		//			if (! (n->childIndex1 == 0xFFFF))
		//				continue;
		//
		//			for (uint32_t s = 0; s < samplesPerCell; s++)
		//			{
		//				vector3f step = vector3f(n->aabbOriginX, n->aabbOriginY, n->aabbOriginZ);
		//				vector3f minCurr = vector3f(n->aabbExtentX, n->aabbExtentY, n->aabbExtentZ);

		NSMutableDictionary *objectsToPVSPerCell = [NSMutableDictionary dictionaryWithCapacity:[objects count]];
		for (i = 0; i < (int)[objects count]; i++)
		{
			NSMutableArray *frames = [NSMutableArray arrayWithCapacity:globalInfo.pvsCells];
			for (int v = 0; v < globalInfo.pvsCells; v++)
				[frames addObject:[NSMutableArray arrayWithCapacity:20]];

			[objectsToPVSPerCell setObject:[NSArray arrayWithArray:frames] forKey:$numi(i)];
		}

		//int trackPointsPerCell = [game.currentTrack trackPoints] / globalInfo.pvsCells;
		for (i = 0; i < globalInfo.pvsCells; i++)
		{
			int firstPoint = (float)[game.currentTrack trackPoints] * (float) i / (float)globalInfo.pvsCells;
			int nextPoint = (float)[game.currentTrack trackPoints] * (float) (i+1) / (float)globalInfo.pvsCells;

			for (int point = firstPoint; point < nextPoint; point++)
			{
				for (int cam = 0; cam < 3; cam ++)
				{
					for (int offset = 0; offset < 3; offset ++)
					{
						//		NSLog(@"i point %i %i", i, point);

						vector3f cur = [game.currentTrack positionAtIndex:point];
						vector3f up = vector3f(0, 1, 0);
						vector3f next = [game.currentTrack positionAtIndex:i+1];

						vector3f perp = cross(up, next-cur).normalize();
						vector3f side = cur + perp * 18;
						vector3f oside = cur - perp * 18;

						vector3f cameraPoint;
						if (cam == 0) cameraPoint = cur;
						if (cam == 1) cameraPoint = side;
						if (cam == 2) cameraPoint = oside;
						float x = cameraOffset[offset][0];
						float y = cameraOffset[offset][1];
						float z = cameraOffset[offset][2];
						vector3f offsetVec = vector3f(x, y, z);

						[ourCam setPosition:cameraPoint + offsetVec];

						for (int rot = 0; rot < 6; rot ++)
						{
							//	glPushMatrix();

							glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
							[ourCam setRotation:vector3f(rots[rot][0], rots[rot][1], rots[rot][2])];
							[ourCam identity];
							[ourCam transform];

							objNum = 0;

							for (Mesh *obj in objects)
							{
								//glPushMatrix();

								[ourCam push];

								[obj transform];

                                [shader prepare];

								objNum++;
								assert(objNum <= 0xFF);

								struct octree_struct *oc = [obj octree];

								glBindBuffer(GL_ARRAY_BUFFER, obj->vertexVBOName);

								glNormalPointer(GL_FLOAT, (oc->magicWord == 0x6D616C62) ? sizeof(float) * 6 : sizeof(float) * 8, (const GLfloat *) (sizeof(float) * 3));
								glVertexPointer(3, GL_FLOAT, (oc->magicWord == 0x6D616C62) ? sizeof(float) * 6 : sizeof(float) * 8, (const GLfloat *) 0);

								glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, obj->indexVBOName);


								assert(oc->nodeCount <= 0xFFFF);

								for (uint16_t i = 0; i < oc->nodeCount; i++)
								{
									struct octree_node *n = (struct octree_node *) _NODE_NUM(oc, i);

									if (n->childIndex1 == 0xFFFF)
									{
										//								NSLog(@"draw obj nod %i %i", objNum, i);
										glColor3ub(objNum, i >> 8, i);

										if 	(oc->vertexCount > 0xFFFF)
										{	glDrawElements(GL_TRIANGLES, n->faceCount * 3, GL_UNSIGNED_INT, (const GLuint *) 0 + (n->firstFace * 3)); }
										else
										{	glDrawElements(GL_TRIANGLES, n->faceCount * 3, GL_UNSIGNED_SHORT, (const GLushort *) 0 + (n->firstFace * 3)); }
									}
								}

								[ourCam pop];
								//	glPopMatrix();
							}

							glBindBuffer(GL_PIXEL_PACK_BUFFER, pboReadback[rot]);

							glGetTexImage(GL_TEXTURE_2D, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, 0);

							glBindBuffer(GL_PIXEL_PACK_BUFFER, 0);


							//	glPopMatrix();

							[[NSOpenGLContext currentContext] flushBuffer];
						}

						for (int rb = 0; rb < 6; rb ++)
						{
							glBindBuffer(GL_PIXEL_PACK_BUFFER, pboReadback[rb]);
							const uint32_t *readbackBuffer = (uint32_t *)glMapBuffer(GL_PIXEL_PACK_BUFFER, GL_READ_ONLY);

							for (uint32_t p = 0; p < 1024 * 1024; p++)
							{
								const uint32_t pixel = readbackBuffer[p];			// BGRA

								if ((pixel != 0xFF000000) && (pixel != 0x00000000))
								{
									visibleNodes[pixel] = 1;
									//					NSLog(@"found  bgra %i %i %i %i", BYTE1(pixel), BYTE2(pixel), BYTE3(pixel), BYTE4(pixel));
								}
							}

							glUnmapBuffer(GL_PIXEL_PACK_BUFFER);
							glBindBuffer(GL_PIXEL_PACK_BUFFER, 0);
						}
					}
					//NSLog(@"6 views complete");
				}
			}
			NSLog(@"cell : %i", i);

			map<uint32_t, uint32_t>::iterator visibleIter;
			for (visibleIter = visibleNodes.begin(); visibleIter != visibleNodes.end(); ++visibleIter)
			{
				const uint32_t pixel = visibleIter->first;			// BGRA

				uint8_t obj = BYTE3(pixel);
				uint16_t node = (((uint16_t)(BYTE2(pixel))) << 8) + BYTE1(pixel);

				NSLog(@"found obj node %@ %i  (%i) bgra %i %i %i %i", [[objects objectAtIndex:obj-1] name], node, [[objects objectAtIndex:obj-1] octree]->nodeCount,  BYTE1(pixel), BYTE2(pixel), BYTE3(pixel), BYTE4(pixel));


				NSArray *pvsPerFrameArray = [objectsToPVSPerCell objectForKey:$numi(obj-1)];
				NSMutableArray *pvsCurrentFrameArray = [pvsPerFrameArray objectAtIndex:i];
				[pvsCurrentFrameArray addObject:$numi(node)];

				visibleNodes.erase(pixel);
			}

			for (NSNumber *objNum in objectsToPVSPerCell)
			{
				Mesh *obj = [objects objectAtIndex:[objNum intValue]];
				NSArray *pvsPerFrameArray = [objectsToPVSPerCell objectForKey:$numi([objNum intValue])];
				NSMutableArray *pvsCurrentFrameArray = [pvsPerFrameArray objectAtIndex:i];


				for (int i = [obj octree]->nodeCount - 1 ; i >= 0; i--)
				{
					struct octree_node *n = (struct octree_node *) _NODE_NUM([obj octree], i);
					if (! (n->childIndex1 == 0xFFFF))
					{

						if ([pvsCurrentFrameArray indexOfObject:$numi(n->childIndex1)] != NSNotFound &&
							[pvsCurrentFrameArray indexOfObject:$numi(n->childIndex2)] != NSNotFound &&
							[pvsCurrentFrameArray indexOfObject:$numi(n->childIndex3)] != NSNotFound &&
							[pvsCurrentFrameArray indexOfObject:$numi(n->childIndex4)] != NSNotFound &&
							[pvsCurrentFrameArray indexOfObject:$numi(n->childIndex5)] != NSNotFound &&
							[pvsCurrentFrameArray indexOfObject:$numi(n->childIndex6)] != NSNotFound &&
							[pvsCurrentFrameArray indexOfObject:$numi(n->childIndex7)] != NSNotFound &&
							[pvsCurrentFrameArray indexOfObject:$numi(n->childIndex8)] != NSNotFound)
						{
							[pvsCurrentFrameArray removeObject:$numi(n->childIndex1)];
							[pvsCurrentFrameArray removeObject:$numi(n->childIndex2)];
							[pvsCurrentFrameArray removeObject:$numi(n->childIndex3)];
							[pvsCurrentFrameArray removeObject:$numi(n->childIndex4)];
							[pvsCurrentFrameArray removeObject:$numi(n->childIndex5)];
							[pvsCurrentFrameArray removeObject:$numi(n->childIndex6)];
							[pvsCurrentFrameArray removeObject:$numi(n->childIndex7)];
							[pvsCurrentFrameArray removeObject:$numi(n->childIndex8)];

							[pvsCurrentFrameArray addObject:$numi(i)];
						}
					}
				}
			}
		}

		for (int i = 0; i < (int)[objects count]; i++)
		{
			NSArray *pvsPerCellArray = [objectsToPVSPerCell objectForKey:$numi(i)];
			int visibleNodeCount = 0;
			for (NSArray *pvs in pvsPerCellArray)
				visibleNodeCount += [pvs count];

			assert([pvsPerCellArray count] == globalInfo.pvsCells);

			int pvsCellsBytes = sizeof(uint16_t) * (1 + globalInfo.pvsCells + 1 + visibleNodeCount);
			uint16_t *pvsCells = (uint16_t *) malloc(pvsCellsBytes);

			int bytesWritten = 0;
			pvsCells[0]	= globalInfo.pvsCells;
			for (int v = 0; v <= globalInfo.pvsCells; v++)
			{
				pvsCells[v+1] = bytesWritten;

				if (v == globalInfo.pvsCells)
					break;
				NSArray *pvs = [pvsPerCellArray objectAtIndex:v];
				for (NSNumber *nodeNum in pvs)
				{
					pvsCells[1+globalInfo.pvsCells+1+bytesWritten] = [nodeNum intValue];
					bytesWritten ++;
				}
			}
			assert(visibleNodeCount == bytesWritten);

			NSData *data = [NSData dataWithBytes:(const void *)pvsCells length:pvsCellsBytes];
			[data writeToFile:[[NSHomeDirectory() stringByAppendingPathComponent:[[objects objectAtIndex:i] name]] stringByAppendingPathExtension:@"pvs"]  atomically:NO];

			Mesh *m = [objects objectAtIndex:i];

			[m setPvsCells:pvsCells];
		}


		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);

		glMatrixMode(GL_MODELVIEW);
		glPopMatrix();
		glPopAttrib();
        [shader release];

		currentCamera = savedCam;
		//
		//		for (int i = 0; i < [game.currentTrack trackPoints]; i++) TODO THEY DONT MATCH
		//			NSLog(@"point %i cell %i", i, (int) ((float)i / ((float)[game.currentTrack trackPoints] / (float)globalInfo.pvsCells)));

	}
		if (globalInfo.frame == 2)
		{
			NSLog(@"done");
            exit(1);
		}
}*/
@end
