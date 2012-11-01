//
//  Shader.h
//  Core3D
//
//  Created by CoreCode on 27.04.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

@interface SubShader : NSObject
{
@public
	GLuint subShaderName;
}

@end

@interface Shader : NSObject
{
	NSMutableDictionary *uniformLocations;
	NSMutableDictionary *uniformValues;

	SubShader *vertexShader, *fragmentShader;
@private
	vector4f savedColor, light1positionSaved, light1product_ambientSaved, light1product_diffuseSaved, light1product_specularSaved, lightmodelproduct_scenecolorSaved, light2positionSaved, light2product_ambientSaved, light2product_diffuseSaved, light2product_specularSaved;
	matrix44f_c savedMVP, savedMV;
	matrix33f_c savedN;
	float savedShininess, light1linearattenuationSaved, light2linearattenuationSaved;

	NSString *name, *defines;
	GLuint shaderName;
	GLint mvpName, mvName, nName, colorName, texUnitPos;
	uint8_t texUnit;

	GLint light1linearattenuationPos, light1positionPos, light1product_ambientPos, light1product_diffusePos, light1product_specularPos, lightmodelproduct_scenecolorPos, light2linearattenuationPos, light2positionPos, light2product_ambientPos, light2product_diffusePos, light2product_specularPos, material_shininessPos;
}

+ (Shader *)newShaderNamed:(NSString *)_name withTexcoordsBound:(BOOL)bindTex andNormalsBound:(BOOL)bindNormals;
+ (Shader *)newShaderNamed:(NSString *)_name withDefines:(NSString *)defines withTexcoordsBound:(BOOL)bindTex andNormalsBound:(BOOL)bindNormals;
+ (NSArray *)allShaders;

- (void)setUniformf:(float)f forKey:(NSString *)key;
- (void)setTexUnit:(uint8_t)_texUnit;
- (void)bind;
- (void)prepare;
- (void)prepareWithModelViewMatrix:(matrix44f_c)mv andProjectionMatrix:(matrix44f_c)p;
- (void)setColor:(vector4f)color;

@property (nonatomic, readonly) GLuint shaderName;

@end
