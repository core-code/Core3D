//
//  OutlineShader.m
//  Core3D
//
//  Created by CoreCode on 13.10.08.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


#import "Core3D.h"
#import "OutlineShader.h"


@implementation OutlineShader

- (void)render // override render instead of implementing renderNode
{
	// main pass
	[children makeObjectsPerformSelector:@selector(render)];

	// edge pass
	if (globalSettings.outlineMode)
	{
		glCullFace(GL_FRONT);
#ifndef GL_ES_VERSION_2_0
		glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
#endif

		if (globalSettings.outlineMode == 1)
			myLineWidth((GLfloat) [scene bounds].width / 800);
		else if (globalSettings.outlineMode == 2)
			myLineWidth((GLfloat) [scene bounds].width / 550);
		else if (globalSettings.outlineMode == 3)
			myLineWidth((GLfloat) [scene bounds].width / 400);


		globalMaterial.color = globalSettings.outlineColor;


		[[scene colorOnlyShader] bind];



		currentRenderPass.settings = kRenderPassUsePVS;
		[children makeObjectsPerformSelector:@selector(render)];
		currentRenderPass.settings = kMainRenderPass;



		glCullFace(GL_BACK);
#ifndef GL_ES_VERSION_2_0
		glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
#endif
	}
}

@end
