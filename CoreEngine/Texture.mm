//
//  Texture.mm
//  Core3D
//
//  Created by CoreCode on 15.11.10.
//  Copyright 2010 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#import "Core3D.h"
#import "Texture.h"


#ifdef REALTIMECOMPRESSION
#include "dxt.h"
#endif
#include "MyDDS.h"


#ifdef TARGET_OS_MAC
#import "MacRenderViewController.h"
#endif

#undef glBindTexture

BOOL textureUnitClaimed[16];
MutableDictionary *namedTextures;

@implementation Texture

@synthesize width;
@synthesize height;
@synthesize texName;
@synthesize internalFormat;
@synthesize format;
@synthesize type;
@synthesize minFilter;
@synthesize magFilter;
@synthesize anisotropy;
@synthesize wrapS;
@synthesize wrapT;
//@synthesize depthTextureMode;
@synthesize compareFunc;
@synthesize compareMode;
@synthesize hasAlpha;
@synthesize name;
@synthesize quality;
@synthesize permanentTextureUnit;

+ (void)initialize
{
	if (!namedTextures)
		namedTextures = new MutableDictionary;

	textureUnitClaimed[0] = YES;
	textureUnitClaimed[5] = YES;
	textureUnitClaimed[6] = YES; // hack for plasma shader
//    int value;
//    glGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS_ARB, &value);
//    if (value < 16)
//        fatal("16 textures not supported");
}

+ (NSArray *)allTextures
{
	NSMutableArray *textures = [NSMutableArray array];

	MutableDictionary::const_iterator end = namedTextures->end();
	for (MutableDictionary::const_iterator it = namedTextures->begin(); it != end; ++it)
		[textures addObject:it->second];


	return textures;
}

+ (Texture *)newTextureNamed:(NSString *)_name
{
	if (namedTextures->count([_name UTF8String]))
	{
		Texture *cachedTexture = (*namedTextures)[[_name UTF8String]];

		assert(cachedTexture);

		return [cachedTexture retain];
	}



	for (NSString *ext in IMG_EXTENSIONS)
	{
		NSURL *url = [[NSBundle mainBundle] URLForResource:_name withExtension:ext];


		if (url)
		{
			Texture *tex = [(Texture *) [self alloc] initWithContentsOfURL:url];
			if (!tex)
				return nil;

			(*namedTextures)[[_name UTF8String]] = tex;

			[tex setName:_name];

			// NSLog(@"created texture named %@ %@ %i", _name, [tex name], [tex texName]);

			return tex;
		}
//        else
//            NSLog(@"didnt find %@ %@", _name, ext);

	}



	//NSLog(@"Warning: could not find texture named: %@", _name);

	return nil;
}

- (Texture *)initWithContentsOfURL:(NSURL *)_url
{
	if (!_url)
	{
		NSLog(@"Warning: can't load nil texture");
		return nil;
	}

	if ((self = [self init]))
	{
#ifndef REALTIMECOMPRESSION
		disabledCompression = 1;
#endif


		if ([[_url pathExtension] isEqualToString:@"dds"])
		{
#ifdef WIN32
			if ([[_url path] hasPrefix:@"/"])
				file = fopen([[[_url path] substringFromIndex:1] UTF8String], "rb");
			else
#endif
			file = fopen([[_url path] UTF8String], "rb");
		}
		else
		{
#if defined(GNUSTEP) || defined(__COCOTRON__)
         //   [NSException raise:@" shit " format:@"bla"];

            NSImage *theImg = [[NSImage alloc] initWithContentsOfURL:_url];
            NSBitmapImageRep *bitmap = [NSBitmapImageRep alloc];
//            int samplesPerPixel = 0;
            NSSize imgSize = [theImg size];

            width = imgSize.width;
			height = imgSize.height;




            [theImg lockFocus];

//            NSAffineTransform *t = [NSAffineTransform transform];
//            [t scaleXBy:1.0 yBy:-1.0];
//            [t translateXBy:0.0 yBy:-imgSize.height];
//            [t concat];



            [bitmap initWithFocusedViewRect:NSMakeRect(0.0, 0.0, imgSize.width, imgSize.height)];
            [theImg unlockFocus];

 //           int bpp = [bitmap bitsPerPixel] / 8;
         
//            NSLog(@" bpp %i %i %i %i %i %i %i", bpp, width, height, (int)[bitmap size].width, (int)[bitmap size].height, (int)[bitmap bytesPerRow], (int)[bitmap bitsPerPixel]);
            const int rowsize = [bitmap bytesPerRow];
            _data = (char *)calloc( rowsize * height, 1);

            for (int i =  0; i < height; i++)
            {
                memcpy(_data + ((height - i - 1) * rowsize), ((const char *)[bitmap bitmapData]) + (i * rowsize), rowsize);
            }

//            memcpy(_data, [bitmap bitmapData], width * bpp * height);

            [theImg release];
            [bitmap release];
//#elif defined(__APPLE__)
//            NSImage *theImg = [[NSImage alloc] initWithContentsOfURL:_url];
//            NSSize imgSize = [theImg size];
//
//            width = imgSize.width;
//			height = imgSize.height;
//
//            _data = (char *)calloc( width * 4 * height, 1);
//
//            const int rowsize = width * 4;
//            NSData *d = [theImg TIFFRepresentationUsingCompression:NSTIFFCompressionNone factor:0.0];
//
//            for (int i =  0; i < height; i++)
//            {
//                memcpy(_data + ((height - i) * rowsize), ((const char *)[d bytes]) + (i * rowsize), rowsize);
//            }
//
//            [theImg release];
//          //  NSLog(@"file

#else
#ifndef TARGET_OS_IPHONE
			CGImageSourceRef imageSourceRef = CGImageSourceCreateWithURL((CFURLRef)_url, NULL);
			CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, NULL);
#else
			if ([[_url pathExtension] isEqualToString:@"pvrtc"])
				pvrTexture = [[PVRTexture alloc] initWithContentsOfFile:[_url path] andName:texName];
			else if ([[NSFileManager defaultManager] fileExistsAtPath:[[[_url path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pvrtc"]])
				pvrTexture = [[PVRTexture alloc] initWithContentsOfFile:[_url path] andName:texName];
			else if ([[NSFileManager defaultManager] fileExistsAtPath:[[_url path] stringByAppendingPathExtension:@"pvrtc"]])
				pvrTexture = [[PVRTexture alloc] initWithContentsOfFile:[_url path] andName:texName];

			if (pvrTexture)
			{
				width = [pvrTexture width];
				height = [pvrTexture height];

				disabledCompression = YES;
				return self;
			}
			CGImageRef imageRef = [UIImage imageWithContentsOfFile:[_url path]].CGImage;
			if (!imageRef)
			{
				NSLog(@"Warning: there is no texture %s\n", [[_url description] UTF8String]);
				return nil;
			}
#endif
			CGImageAlphaInfo ai = CGImageGetAlphaInfo(imageRef);


			if ((ai == kCGImageAlphaNone) || (ai == kCGImageAlphaNoneSkipLast) || (ai == kCGImageAlphaNoneSkipFirst))
				hasAlpha = FALSE;
			else
				hasAlpha = TRUE;



			CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
			width = CGImageGetWidth(imageRef);
			height = CGImageGetHeight(imageRef);

			if (width != height)
			{
//#ifdef DEBUG
//                printf("Warning: loading a non square texture from disk! %s\n", [[_url description] UTF8String]);
//#endif
				minFilter = GL_LINEAR;
				wrapS = GL_CLAMP_TO_EDGE;
				wrapT = GL_CLAMP_TO_EDGE;
				disabledCompression = YES;
			}

			if ((!disabledCompression) && ((width % 4 != 0) || (height) % 4 != 0))
				fatal("Error: texture compression is enabled and texture is not a multiple of 4 %s", [[_url description] UTF8String]);

			_data = (char *) calloc((width * 4 * height * ((!disabledCompression) ? 4 : 3)) / 3, 1);

			size_t ourWidth = (int) width;
			size_t ourHeight = (int) height;
			int offset = 0;
			do
			{
				CGRect rect = {{0, 0}, {ourWidth, ourHeight}};

#ifdef TARGET_OS_IPHONE
				CGContextRef bitmapContext = CGBitmapContextCreate(_data + offset, ourWidth, ourHeight, 8, ourWidth * 4, rgb, kCGImageAlphaPremultipliedLast); //
#else
				CGContextRef bitmapContext = CGBitmapContextCreate(_data + offset, ourWidth, ourHeight, 8, ourWidth * 4, rgb, disabledCompression ? (kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little) : (kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big)); //
#endif


				CGContextTranslateCTM(bitmapContext, 0, ourHeight);
				CGContextScaleCTM(bitmapContext, 1.0, -1.0);

				CGContextDrawImage(bitmapContext, rect, imageRef);

				CGContextRelease(bitmapContext);

				offset += ourWidth * 4 * ourHeight;
				ourWidth /= 2;
				ourHeight /= 2;
			} while ((ourHeight != 1) && (ourWidth != 1) && (!disabledCompression));


#ifndef TARGET_OS_IPHONE
            CGImageRelease(imageRef);
			CFRelease(imageSourceRef);
#endif
			CGColorSpaceRelease(rgb);
#endif
		}
	}

	return self;
}

- (id)init
{
	if ((self = [super init]))
	{
//#if defined(__APPLE__) && defined(DEBUG)
//        if (![[RenderViewController sharedController] loadingWindow] && [NSThread isMainThread]) fatal("doing things on main instead of render thread");
//#endif

		glGenTextures(1, &texName);

		minFilter = GL_LINEAR_MIPMAP_LINEAR;
		magFilter = GL_LINEAR;
		anisotropy = 0;
		wrapS = GL_REPEAT;
		wrapT = GL_REPEAT;
//		depthTextureMode = GL_LUMINANCE;
		compareMode = GL_NONE;
		compareFunc = GL_LEQUAL;

		internalFormat = GL_RGBA;
#ifdef TARGET_OS_MAC
		format = GL_BGRA;
#else
		format = GL_RGBA;
#endif
#ifdef GL_ES_VERSION_2_0
		type = GL_UNSIGNED_BYTE;
#else
		type = GL_UNSIGNED_INT_8_8_8_8_REV;
#endif

		quality = (short) $defaulti(kTextureQualityKey);
	}

	return self;
}

- (void)setParameters
{
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, minFilter);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, magFilter);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrapS);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrapT);
#ifndef GL_ES_VERSION_2_0
//	glTexParameteri(GL_TEXTURE_2D, GL_DEPTH_TEXTURE_MODE, depthTextureMode);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_FUNC, compareFunc);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, compareMode);
#endif

	if (anisotropy > 1.0)
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, anisotropy);
}

- (void)load
{
	if (loaded && name)
		return;


	if (!loaded)
	{
		[self addObserver:self forKeyPath:@"minFilter" options:NSKeyValueObservingOptionNew context:NULL];
		[self addObserver:self forKeyPath:@"magFilter" options:NSKeyValueObservingOptionNew context:NULL];
		[self addObserver:self forKeyPath:@"anisotropy" options:NSKeyValueObservingOptionNew context:NULL];
		[self addObserver:self forKeyPath:@"wrapS" options:NSKeyValueObservingOptionNew context:NULL];
		[self addObserver:self forKeyPath:@"wrapT" options:NSKeyValueObservingOptionNew context:NULL];
//        [self addObserver:self forKeyPath:@"depthTextureMode" options:NSKeyValueObservingOptionNew context:NULL];
		[self addObserver:self forKeyPath:@"compareFunc" options:NSKeyValueObservingOptionNew context:NULL];
		[self addObserver:self forKeyPath:@"compareMode" options:NSKeyValueObservingOptionNew context:NULL];
	}

	//	glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
	//	glPixelStorei(GL_UNPACK_ROW_LENGTH, width);
	//	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

	glBindTexture(GL_TEXTURE_2D, texName);
	currentTexture = self;

	if (!loaded)
		[self setParameters];


#ifdef TARGET_OS_IPHONE
	if (pvrTexture)
	{
		if (![pvrTexture createGLTexture])
			fatal("Error: PVR texture loading failed");


		[pvrTexture release];
		pvrTexture = nil;
	}
	else
#else
	if (file)
	{
		DdsLoadInfo info;
		info = loadDds(file, quality);
		internalFormat = info.internalFormat;
		width = info.width;
		height = info.height;
		//NSLog(@"Loading compressed texture %i %@ (%i) quality %i", (int)width, name, texName, quality);
		fclose (file);
		file = NULL;
	}
#ifdef REALTIMECOMPRESSION
	else if (_data && !disabledCompression)
	{

		internalFormat = hasAlpha ? GL_COMPRESSED_RGBA_S3TC_DXT5_EXT : GL_COMPRESSED_RGB_S3TC_DXT1_EXT;

		int ourWidth = (int)width;
		int ourHeight = (int)height;
		int offset = 0;
		int times = 0;
		int out_bytes = 0;
		uint8_t *out;

		//NSLog(@"realtime compressing and loading texture %i %@", (int)width, name);



		do {
			if (!hasAlpha)
			{
				out = (uint8_t *)malloc((ourWidth+3)*(ourHeight+3)/16*8);

				CompressImageDXT1((const byte *)_data+offset, (byte *)out, ourWidth, ourHeight, out_bytes);
			}
			else
			{
				out = (uint8_t *)malloc((ourWidth+3)*(ourHeight+3)/16*16);

				CompressImageDXT5((const byte*)_data+offset, (byte *)out, ourWidth, ourHeight, out_bytes);
			}

			glCompressedTexImage2D(GL_TEXTURE_2D, times, internalFormat, ourWidth, ourHeight, 0, /*ourWidth * ourHeight / (hasAlpha ? 1 : 2)*/out_bytes, out);
			//		NSLog(@"sending to graka w h  off %i %i %i", ourWidth, ourHeight, offset);
			free(out);
			offset += ourWidth * 4 * ourHeight;
			times ++;


			//	} while ((ourWidth >= 2) && (ourHeight >= 2) && (ourHeight /= 2) && (ourWidth /= 2));

		} while (((ourWidth / 2) * 2 == ourWidth) && ((ourHeight / 2) * 2 == ourHeight) && ((ourWidth / 2) % 4 == 0) && ((ourHeight / 2) % 4 == 0) && (ourWidth >= 8) && (ourHeight >= 8) && (ourHeight /= 2) && (ourWidth /= 2));


		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, times-1);
    }
#endif
    else
#endif
	{
#ifndef TARGET_OS_IPHONE
		assert(internalFormat != GL_COMPRESSED_RGBA_S3TC_DXT5_EXT && internalFormat != GL_COMPRESSED_RGB_S3TC_DXT1_EXT);
#endif

		//NSLog(@"Loading uncompressed texture %i %@", (int)width, name);
		glTexImage2D(GL_TEXTURE_2D, 0, internalFormat, (GLsizei) width, (GLsizei) height, 0, format, type, _data);

#ifndef TARGET_OS_IPHONE // getting GL_INVALID_OPERATION, perhaps because its npot
		if (_data && (minFilter == GL_LINEAR_MIPMAP_LINEAR ||
				minFilter == GL_NEAREST_MIPMAP_LINEAR ||
				minFilter == GL_LINEAR_MIPMAP_NEAREST ||
				minFilter == GL_NEAREST_MIPMAP_NEAREST))
			glGenerateMipmap(GL_TEXTURE_2D);
#endif
	}



	//	glPopClientAttrib();


	if (_data)
		free(_data);
	_data = NULL;
	loaded = TRUE;
}

- (NSString *)description
{
	return [NSString stringWithString:$stringf(@"<Texture: %p loaded %i name %@ width %li height %li>", self, loaded, name, width, height)];
}

- (uint8_t)permanentlyBind
{
	for (int i = 1; i < 16; i++)
	{
		if (!textureUnitClaimed[i])
		{
			textureUnitClaimed[i] = YES;

			glActiveTexture(GL_TEXTURE0 + i);

			glBindTexture(GL_TEXTURE_2D, texName);

			glActiveTexture(GL_TEXTURE0);

			permanentTextureUnit = i;
//            NSLog(@"permanently bound to %@ %i", [self description], i);
			break;
		}
	}
	return permanentTextureUnit;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self bind];
	[self setParameters];
}

- (void)bind
{
	assert(loaded);


	if (permanentTextureUnit)
	{
		[currentShader setTexUnit:permanentTextureUnit];

		return;
	}

	if (currentTexture == self)
	{
		assert(myGetInteger(GL_TEXTURE_BINDING_2D) == (GLint) texName);

		return;
	}

	glBindTexture(GL_TEXTURE_2D, texName);
	currentTexture = self;
}

- (void)dealloc
{
#if defined(TARGET_OS_MAC) && defined(DEBUG) && !defined(SDL)
    if (![[RenderViewController sharedController] loadingWindow] && [NSThread isMainThread]) fatal("doing things on main instead of render thread");
#endif

	if (name)
	{
		namedTextures->erase([name UTF8String]);
//		NSLog(@"tex release %@ (%i)", name, texName);
	}

	if (permanentTextureUnit)
		textureUnitClaimed[permanentTextureUnit] = NO;

	if (_data)
		free(_data);
	_data = NULL;

	[name release];

	if (loaded)
	{
		[self removeObserver:self forKeyPath:@"minFilter"];
		[self removeObserver:self forKeyPath:@"magFilter"];
		[self removeObserver:self forKeyPath:@"anisotropy"];
		[self removeObserver:self forKeyPath:@"wrapS"];
		[self removeObserver:self forKeyPath:@"wrapT"];
//		[self removeObserver:self forKeyPath:@"depthTextureMode"];
		[self removeObserver:self forKeyPath:@"compareFunc"];
		[self removeObserver:self forKeyPath:@"compareMode"];
	}

	if (currentTexture == self)
	{
		currentTexture = nil;
		glBindTexture(GL_TEXTURE_2D, 0);
	}
	glDeleteTextures(1, &texName);

	[super dealloc];
}
@end
