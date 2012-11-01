//
//  RenderPass.h
//  Core3D
//
//  Created by CoreCode on 21.11.10.
//  Copyright 2010 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


typedef enum
{
	kRenderPassSetMaterial = 1,
	kRenderPassUseTexture = 2,
	kRenderPassUpdateCulling = 4,
	kRenderPassUsePVS = 8,

	kMainRenderPass = 15,
	kAdditionalRenderPass = 0
} renderPassEnum;

@interface RenderPass : NSObject
{
	cml::matrix44d_c viewportMatrix;
	renderPassEnum settings;
	Camera *camera;
	MutableLightArray *lights;
	MutableSceneNodeArray *objects;
	RenderTarget *renderTarget;
	int autoresizingMask;
	CGRect frame;
	int16_t currentPVSCell;
}

+ (RenderPass *)mainRenderPass;
+ (RenderPass *)shadowRenderPassWithSize:(int)size light:(Light *)light casters:(NSArray *)casters andMainCamera:(Camera *)mainCamera;
- (id)initWithFrame:(CGRect)_frame andAutoresizingMask:(int)_mask;
- (void)reshape:(CGSize)size;
- (void)render;
- (NSArray *)newListOfAllObjects;

@property (retain, nonatomic) Camera *camera;
@property (readonly, nonatomic) MutableLightArray *lights;
@property (readonly, nonatomic) MutableSceneNodeArray *objects;
@property (retain, nonatomic) RenderTarget *renderTarget;
@property (readonly, nonatomic) cml::matrix44d_c viewportMatrix;

@property (assign, nonatomic) renderPassEnum settings;
@property (assign, nonatomic) int autoresizingMask;
@property (assign, nonatomic) CGRect frame;
@property (assign, nonatomic) int16_t currentPVSCell;

@end


//@protocol RenderTarget
//
//- (void)reshape:(CGSize)size;
//- (void)bind;
//- (void)unbind;
//
//@end
