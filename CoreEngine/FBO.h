//
//  FBO.h
//  Core3D
//
//  Created by CoreCode on 20.11.10.
//  Copyright 2010 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#import "Texture.h"


@interface FBO : RenderTarget
{
	Texture *colorTexture;
	Texture *depthTexture;
	GLuint fbo;

	BOOL disableDepthTexture;
	BOOL disableColorTexture;
}



- (void)load;

@property (nonatomic, readonly) Texture *colorTexture;
@property (nonatomic, readonly) Texture *depthTexture;
@property (nonatomic, assign) BOOL disableDepthTexture;
@property (nonatomic, assign) BOOL disableColorTexture;
@end
