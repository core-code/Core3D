//
//  DynamicNode.m
//  CoreBreach
//
//  Created by CoreCode on 01.11.11.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#import "Core3D.h"
#import "DynamicNode.h"


#undef glEnable
#undef glDisable

@implementation DynamicNode

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithTextureNamed:(NSString *)textureName
{
	if ((self = [super init]))
	{
		texture = [Texture newTextureNamed:textureName];
		[texture load];

		vbuffer = new vector<vertex>();
	}
	return self;
}

- (void)addVertices:(const vertex *)vertices count:(size_t)count
{
	for (size_t i = 0; i < count; i++)
	{
		vbuffer->push_back(*vertices);
		vertices++;
	}
}

- (void)renderNode
{

	if ([currentRenderPass settings] != kMainRenderPass)
		return;


	myPolygonOffset(-40, 0);
	glEnable(GL_POLYGON_OFFSET_FILL);

	myEnableBlendParticleCullDepthtestDepthwrite(YES, NO, YES, YES, YES);
	myBlendFunc(GL_DST_COLOR, GL_ZERO); // additive blending

	globalMaterial.color = vector4f(1.0f, 1.0f, 1.0f, 1.0f);
	myClientStateVTN(kNeedEnabled, kNeedEnabled, kNeedDisabled);

	[currentShader prepare];
	[texture bind];


	glVertexAttribPointer(VERTEX_ARRAY, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), &(vbuffer->front().x));
	glVertexAttribPointer(TEXTURE_COORD_ARRAY, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), &(vbuffer->front().u));

	glDrawArrays(GL_TRIANGLES, 0, vbuffer->size());

//    glBegin(GL_TRIANGLES);
//    vector<vertex>::iterator it;
//    for (it=vbuffer->begin(); it < vbuffer->end(); it++)
//    {
//        vertex v = (vertex)(*it);
//        glVertex3f(v.x, v.y, v.z);
//        NSLog(@" x y z u v %f %f %f %f %f", v.x, v.y, v.z, v.u, v.v);
//        glTexCoord2f(v.u, v.v);
//    }
//    glEnd();


	globalInfo.drawCalls++;
	/*DRAW_CALL*/

	vbuffer->clear();

	glDisable(GL_POLYGON_OFFSET_FILL);
}

- (void)dealloc
{
	[texture release];

	delete vbuffer;

	[super dealloc];
}
@end
