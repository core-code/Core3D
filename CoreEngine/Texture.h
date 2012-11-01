//
//  Texture.h
//  Core3D
//
//  Created by CoreCode on 15.11.10.
//  Copyright 2010 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#ifdef TARGET_OS_IPHONE
#import "PVRTexture.h"


#endif

@interface Texture : NSObject
{
	BOOL disabledCompression;
	FILE *file;
	BOOL hasAlpha;
	BOOL loaded;
	NSString *name;
	size_t width;
	size_t height;
	GLuint texName;
	GLenum internalFormat;
	GLenum format;
	GLenum type;

	GLint minFilter;
	GLint magFilter;
	GLint anisotropy;
//	GLint depthTextureMode;
	GLint wrapS;
	GLint wrapT;
	GLint compareFunc;
	GLint compareMode;

	uint8_t permanentTextureUnit;
	short quality;

#ifdef TARGET_OS_IPHONE
	PVRTexture *pvrTexture;
#endif

@public
	char *_data;
}

+ (Texture *)newTextureNamed:(NSString *)_name;
+ (NSArray *)allTextures;
- (Texture *)initWithContentsOfURL:(NSURL *)_url;
- (void)bind;
- (void)load;
- (uint8_t)permanentlyBind;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, readonly) BOOL hasAlpha;
@property (nonatomic, readonly) uint8_t permanentTextureUnit;
@property (nonatomic, readonly) GLuint texName;
@property (nonatomic, assign) GLint minFilter;
@property (nonatomic, assign) GLint magFilter;
@property (nonatomic, assign) GLint anisotropy;
//@property (nonatomic, assign) GLint depthTextureMode;
@property (nonatomic, assign) GLint wrapS;
@property (nonatomic, assign) GLint wrapT;
@property (nonatomic, assign) GLint compareFunc;
@property (nonatomic, assign) GLint compareMode;
@property (nonatomic, assign) GLenum internalFormat;
@property (nonatomic, assign) GLenum format;
@property (nonatomic, assign) GLenum type;
@property (nonatomic, assign) size_t width;
@property (nonatomic, assign) size_t height;
@property (nonatomic, assign) short quality;
@end
