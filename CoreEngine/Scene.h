//
//  Scene.h
//  Core3D
//
//  Created by CoreCode on 16.11.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


@interface Scene : NSObject
{

	CGSize bounds;

	RenderPass *mainRenderPass;
	MutableRenderPassArray *renderpasses;
	MutableSceneNodeArray *objects;
	NSMutableArray *_renderTargets;

	Simulation *simulator;

	Shader *textureOnlyShader;
	Shader *colorOnlyShader;
	Shader *phongOnlyShader;
	Shader *phongTextureShader;

	RenderPass *defaultRenderPass;
}

@property (readonly, nonatomic) Shader *textureOnlyShader;
@property (readonly, nonatomic) Shader *colorOnlyShader;
@property (readonly, nonatomic) Shader *phongOnlyShader;
@property (readonly, nonatomic) Shader *phongTextureShader;
@property (readonly, nonatomic) MutableRenderPassArray *renderpasses;
@property (readonly, nonatomic) MutableSceneNodeArray *objects;
@property (readonly, nonatomic) CGSize bounds;
@property (retain, nonatomic) Simulation *simulator;
@property (retain, nonatomic) RenderPass *mainRenderPass;

- (void)resetState;
- (void)update:(CFAbsoluteTime)time;
- (void)render;
- (void)reshape:(CGSize)size;
- (void)addRenderTarget:(RenderTarget *)rt;
- (void)removeRenderTarget:(RenderTarget *)rt;
- (void)removeNode:(SceneNode *)node;

@end

@interface Scene (Sound)

- (void)initSound;

@end