//
//  Shader.m
//  Core3D
//
//  Created by CoreCode on 27.04.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#import "Shader.h"
#import "Core3D.h"

#ifdef TARGET_OS_MAC
#import "MacRenderViewController.h"
#endif

#undef glUseProgram

MutableDictionaryA *namedObjects;

@implementation SubShader

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (SubShader *)initWithString:(const char *)string isFrament:(BOOL)fragment
{
	if ((self = [super init]))
	{
//#if defined(TARGET_OS_MAC) && defined(DEBUG) && !defined(SDL)
//        if (![[RenderViewController sharedController] loadingWindow] && [NSThread isMainThread]) fatal("doing things on main instead of render thread");
//#endif

		GLint shaderCompiled, infoLogLength;

		assert(string);

		subShaderName = glCreateShader(fragment ? GL_FRAGMENT_SHADER : GL_VERTEX_SHADER);
		glShaderSource(subShaderName, 1, &string, NULL);
		glCompileShader(subShaderName);

		glGetShaderiv(subShaderName, GL_COMPILE_STATUS, &shaderCompiled);

		glGetShaderiv(subShaderName, GL_INFO_LOG_LENGTH, &infoLogLength);

		if (infoLogLength > 4)
		{
			char *infoLog = (char *) malloc((infoLogLength + 1) * sizeof(char));
			glGetShaderInfoLog(subShaderName, infoLogLength, NULL, infoLog);
			if (!CONTAINS([NSString stringWithUTF8String:infoLog], @"successfully" ) || CONTAINS([NSString stringWithUTF8String:infoLog], @"error" ))
				NSLog(@"Warning: shader log: %i %s\n", infoLogLength, infoLog);
			free(infoLog);
		}
		if (!shaderCompiled)
		{
			glDeleteShader(subShaderName);
			fatal("Error: couldn't compile shader: \n%s", string); // should do cleanup if we don't wanna panic here
		}
	}
	return self;
}

- (void)dealloc
{
	glDeleteShader(subShaderName);
	[super dealloc];
}
@end

@implementation Shader

@synthesize shaderName;


+ (void)initialize
{
	if (!namedObjects)
		namedObjects = new MutableDictionaryA;
}

- (BOOL)linkWithTexcoordsBound:(BOOL)bindTex andNormalsBound:(BOOL)bindNormals
{
	GLint linked;

	shaderName = glCreateProgram();

	glAttachShader(shaderName, vertexShader->subShaderName);


	glAttachShader(shaderName, fragmentShader->subShaderName);

	glBindAttribLocation(shaderName, VERTEX_ARRAY, "vertex");
	if (bindNormals)
		glBindAttribLocation(shaderName, NORMAL_ARRAY, "normal");
	if (bindTex)
		glBindAttribLocation(shaderName, TEXTURE_COORD_ARRAY, "texcoord0");

	glLinkProgram(shaderName);
	glGetProgramiv(shaderName, GL_LINK_STATUS, &linked);

	if (!linked)
	{
		GLint infoLogLength;
		glGetProgramiv(shaderName, GL_INFO_LOG_LENGTH, &infoLogLength);
		char *infoLog = (char *) malloc((infoLogLength + 1) * sizeof(char));
		glGetProgramInfoLog(shaderName, infoLogLength, NULL, infoLog);


		NSLog(@"Warning: shader log: %i %s\n", infoLogLength, infoLog);
		free(infoLog);

		return NO;
	}

	glUseProgram(shaderName);

	texUnitPos = glGetUniformLocation(shaderName, "texUnit");
	mvpName = glGetUniformLocation(shaderName, "modelViewProjectionMatrix");
	mvName = glGetUniformLocation(shaderName, "modelViewMatrix");
	nName = glGetUniformLocation(shaderName, "normalMatrix");
	colorName = glGetUniformLocation(shaderName, "color");
	light1linearattenuationPos = glGetUniformLocation(shaderName, "light1linearattenuation");
	light1positionPos = glGetUniformLocation(shaderName, "light1position");
	light1product_ambientPos = glGetUniformLocation(shaderName, "light1product_ambient");
	light1product_diffusePos = glGetUniformLocation(shaderName, "light1product_diffuse");
	light1product_specularPos = glGetUniformLocation(shaderName, "light1product_specular");

	light2linearattenuationPos = glGetUniformLocation(shaderName, "light2linearattenuation");
	light2positionPos = glGetUniformLocation(shaderName, "light2position");
	light2product_ambientPos = glGetUniformLocation(shaderName, "light2product_ambient");
	light2product_diffusePos = glGetUniformLocation(shaderName, "light2product_diffuse");
	light2product_specularPos = glGetUniformLocation(shaderName, "light2product_specular");
	lightmodelproduct_scenecolorPos = glGetUniformLocation(shaderName, "lightmodelproduct_scenecolor");
	material_shininessPos = glGetUniformLocation(shaderName, "material_shininess");


	texUnit = 255;
	[self setTexUnit:0];

	glUseProgram(0);
	currentShader = nil;

	return YES;
}

- (void)setTexUnit:(uint8_t)_texUnit
{
	if (_texUnit != texUnit)
	{
		texUnit = _texUnit;
		glUniform1i(texUnitPos, texUnit);
	}
}

- (void)setUniformf:(float)f forKey:(NSString *)key
{
	assert(currentShader == self);


	NSNumber *oldValue = [uniformValues valueForKey:key];
	if (oldValue && [oldValue floatValue] == f)
		return;
	else
		[uniformValues setValue:$num(f) forKey:key];


	NSNumber *pos = [uniformLocations valueForKey:key];
	if (!pos)
	{
		GLint posi = glGetUniformLocation(self.shaderName, [key UTF8String]);
		pos = $numi(posi);
		[uniformLocations setValue:pos forKey:key];
	}


	glUniform1f([pos intValue], f);
}

- (void)initStuff
{
	uniformValues = [[NSMutableDictionary alloc] init];
	uniformLocations = [[NSMutableDictionary alloc] init];
}

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (Shader *)initWithFragment:(SubShader *)fragment andVertex:(SubShader *)vertex andName:(NSString *)_name andDefines:(NSString *)_defines withTexcoordsBound:(BOOL)bindTex andNormalsBound:(BOOL)bindNormals
{
	self = [super init];
	if (self)
	{
		fragmentShader = [fragment retain];
		vertexShader = [vertex retain];

		name = [_name copy];
		defines = [_defines copy];


		BOOL succ = [self linkWithTexcoordsBound:bindTex andNormalsBound:bindNormals];
		if (!succ)
			fatal("Error: couldn't re-link shaders %s", [name UTF8String]);

		[self initStuff];
	}

	return self;
}

- (Shader *)initWithName:(NSString *)_name andDefines:(NSString *)_defines withTexcoordsBound:(BOOL)bindTex andNormalsBound:(BOOL)bindNormals
{
	self = [super init];
	if (self)
	{
		name = [_name copy];
		defines = [_defines copy];

		NSString *vertexString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:_name ofType:@"vert"] encoding:NSUTF8StringEncoding error:NULL];
		NSString *fragmentString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:_name ofType:@"frag"] encoding:NSUTF8StringEncoding error:NULL];

		NSString *openglSupport;
#ifdef GL_ES_VERSION_2_0
		openglSupport = @"precision highp float;\n"\
                        @"    #define varying_frag varying\n"\
                        @"    #define varying_vert varying\n"\
                        @"    #define fragColor gl_FragColor\n";
#else
        openglSupport = globalInfo.modernOpenGL ? @"#version 140\n" :  @"#version 120\n";
        openglSupport = [openglSupport stringByAppendingString:\
                        @"#if __VERSION__ >= 140\n" \
                        @"    #define varying_frag in\n"\
                        @"    #define varying_vert out\n"\
                        @"    #define attribute in\n"\
                        @"    #define texture2D texture\n"\
                        @"    #define texture1D texture\n"\
                        @"    out vec4 fragColor;\n"\
                        @"#else\n"\
                        @"    #define varying_frag varying\n"\
                        @"    #define varying_vert varying\n"\
                        @"    #define fragColor gl_FragColor\n"\
                        @"#endif\n"];
#endif
		if (!vertexString || !fragmentString)
			fatal("Error: can't load empty shaders %s", [_name UTF8String]);

		if (_defines == nil) _defines = openglSupport;
		else _defines = [openglSupport stringByAppendingString:_defines];


		fragmentShader = [[SubShader alloc] initWithString:[[_defines stringByAppendingString:fragmentString] UTF8String] isFrament:YES];
		vertexShader = [[SubShader alloc] initWithString:[[_defines stringByAppendingString:vertexString] UTF8String] isFrament:NO];

		if (![self linkWithTexcoordsBound:bindTex andNormalsBound:bindNormals])
		{
			fatal("Error: couldn't link shaders %s", [name UTF8String]);
		}

		[self initStuff];
	}

	return self;
}

+ (NSArray *)allShaders
{
	NSMutableArray *shaders = [NSMutableArray array];

	MutableDictionaryA::const_iterator end = namedObjects->end();
	for (MutableDictionaryA::const_iterator it = namedObjects->begin(); it != end; ++it)
	{
		MutableArray *cachedObjects = it->second;
		if (cachedObjects->size())
			[shaders addObject:cachedObjects->front()];
	}

	return shaders;
}

+ (Shader *)newShaderNamed:(NSString *)_name withTexcoordsBound:(BOOL)bindTex andNormalsBound:(BOOL)bindNormals
{
	return [Shader newShaderNamed:_name withDefines:nil withTexcoordsBound:bindTex andNormalsBound:bindNormals];
}

+ (Shader *)newShaderNamed:(NSString *)_name withDefines:(NSString *)defines withTexcoordsBound:(BOOL)bindTex andNormalsBound:(BOOL)bindNormals
{
	NSString *key = defines ? [_name stringByAppendingString:defines] : _name;

	if (namedObjects->count([key UTF8String]))
	{
		MutableArray *cachedObjects = (*namedObjects)[[key UTF8String]];


		if (cachedObjects->size())
		{
			Shader *cachedObject = cachedObjects->front();

			Shader *s = [[Shader alloc] initWithFragment:cachedObject->fragmentShader
			                                   andVertex:cachedObject->vertexShader
					                             andName:_name
							                  andDefines:defines
									  withTexcoordsBound:bindTex
										 andNormalsBound:bindNormals];

			cachedObjects->push_back((id) s);

			// NSLog(@"shader init cached %@ %x", defines ? [_name stringByAppendingString:defines] : _name, s);

			return s;
		}
	}


	Shader *s = [[Shader alloc] initWithName:_name
	                              andDefines:defines
			              withTexcoordsBound:bindTex
							 andNormalsBound:bindNormals];

	if (!namedObjects->count([key UTF8String]))
	{
		MutableArray *cachedObjects = new MutableArray;

		(*namedObjects)[[key UTF8String]] = cachedObjects;

		cachedObjects->push_back((id) s);
	}
	else
	{
		MutableArray *cachedObjects = (*namedObjects)[[key UTF8String]];

		cachedObjects->push_back((id) s);
	}

	//  NSLog(@"shader init uncached %@ %x", defines ? [_name stringByAppendingString:defines] : _name, s);

	return s;
}

- (void)bind
{
	//   assert(!currentShader);

	if (currentShader == self)
	{
		assert(myGetInteger(GL_CURRENT_PROGRAM) == (GLint) shaderName);

		return;
	}

	glUseProgram(shaderName);
	currentShader = self;
}

- (void)setColor:(vector4f)color
{
	if (colorName >= 0 && savedColor != color)
	{
		glUniform4fv(colorName, 1, color.data());

		savedColor = color;
	}
}

- (void)prepare
{
	[self prepareWithModelViewMatrix:[currentCamera modelViewMatrix]
	             andProjectionMatrix:[currentCamera projectionMatrix]];
}

- (void)prepareWithModelViewMatrix:(matrix44f_c)mv andProjectionMatrix:(matrix44f_c)p
{
	matrix33f_c v33;
	if ((light1positionPos >= 0) || (light2positionPos >= 0))
		cml::matrix_linear_transform(v33, [currentCamera viewMatrix]);



	assert(currentShader == self);
	matrix44f_c mvp = (p * mv);

	if (mvpName >= 0 && mvp != savedMVP)
	{
		glUniformMatrix4fv(mvpName, 1, GL_FALSE, matrix44f_c(p * mv).data());
		savedMVP = mvp;
	}

	if (mvName >= 0 && mv != savedMV)
	{
		glUniformMatrix4fv(mvName, 1, GL_FALSE, mv.data());
		savedMV = mv;
	}


// TODO: independent of light count
	if (nName >= 0)
	{
		matrix33f_c mv33;

		cml::matrix_linear_transform(mv33, mv);

		matrix33f_c n = transpose(inverse(mv33));
		if (n != savedN)
		{
			glUniformMatrix3fv(nName, 1, GL_FALSE, n.data());
			savedN = n;
		}
	}


	[self setColor:globalMaterial.color];


	if (light1positionPos >= 0)
	{
		Light *light = [[currentRenderPass lights] objectAtIndex:globalMaterial.activeLightIndices[0]];

		vector4f light1position = vector4f(([currentCamera viewMatrix]) * vector4f([light aggregatePosition], 1.0f));
		if (light1position != light1positionSaved)
		{
			glUniform3fv(light1positionPos, 1, light1position.data());
			light1positionSaved = light1position;
		}

		if (light1linearattenuationPos >= 0 && [light linearAttenuation] != light1linearattenuationSaved)
		{
			glUniform1f(light1linearattenuationPos, [light linearAttenuation]);
			light1linearattenuationSaved = [light linearAttenuation];
		}

		vector4f light1product_ambient = component_mult4([light lightAmbientColor], globalMaterial.color);
		if (light1product_ambientPos >= 0 && light1product_ambient != light1product_ambientSaved)
		{
			glUniform4fv(light1product_ambientPos, 1, light1product_ambient.data());
			light1product_ambientSaved = light1product_ambient;
		}

		vector4f light1product_diffuse = component_mult4([light lightDiffuseColor], globalMaterial.color);
		if (light1product_diffusePos >= 0 && light1product_diffuse != light1product_diffuseSaved)
		{
			glUniform4fv(light1product_diffusePos, 1, light1product_diffuse.data());
			light1product_diffuseSaved = light1product_diffuse;
		}

		vector4f light1product_specular = component_mult4([light lightSpecularColor], globalMaterial.specular);
		if (light1product_specularPos >= 0 && light1product_specular != light1product_specularSaved)
		{
			glUniform4fv(light1product_specularPos, 1, light1product_specular.data());
			light1product_specularSaved = light1product_specular;
		}
	}

	if (light2positionPos >= 0)
	{
		Light *light = [[currentRenderPass lights] objectAtIndex:globalMaterial.activeLightIndices[1]];

		vector4f light2position = vector4f(([currentCamera viewMatrix]) * vector4f([light aggregatePosition], 1.0f));
		if (light2position != light2positionSaved)
		{
			glUniform3fv(light2positionPos, 1, light2position.data());
			light2positionSaved = light2position;
		}

		if (light2linearattenuationPos >= 0 && [light linearAttenuation] != light2linearattenuationSaved)
		{
			glUniform1f(light2linearattenuationPos, [light linearAttenuation]);
			light2linearattenuationSaved = [light linearAttenuation];
		}

		vector4f light2product_ambient = component_mult4([light lightAmbientColor], globalMaterial.color);
		if (light2product_ambientPos >= 0 && light2product_ambient != light2product_ambientSaved)
		{
			glUniform4fv(light2product_ambientPos, 1, light2product_ambient.data());
			light2product_ambientSaved = light2product_ambient;
		}

		vector4f light2product_diffuse = component_mult4([light lightDiffuseColor], globalMaterial.color);
		if (light2product_diffusePos >= 0 && light2product_diffuse != light2product_diffuseSaved)
		{
			glUniform4fv(light2product_diffusePos, 1, light2product_diffuse.data());
			light2product_diffuseSaved = light2product_diffuse;
		}

		vector4f light2product_specular = component_mult4([light lightSpecularColor], globalMaterial.specular);
		if (light2product_specularPos >= 0 && light2product_specular != light2product_specularSaved)
		{
			glUniform4fv(light2product_specularPos, 1, light2product_specular.data());
			light2product_specularSaved = light2product_specular;
		}
	}

	if (lightmodelproduct_scenecolorPos >= 0)
	{
		vector4f lightmodelproduct_scenecolor = vector4f(globalMaterial.emission + component_mult4(globalMaterial.color, globalMaterial.lightModelAmbient));

		if (lightmodelproduct_scenecolorSaved != lightmodelproduct_scenecolor)
		{
			glUniform4fv(lightmodelproduct_scenecolorPos, 1, lightmodelproduct_scenecolor.data());
			lightmodelproduct_scenecolorSaved = lightmodelproduct_scenecolor;
		}
	}

	if (material_shininessPos >= 0 && globalMaterial.shininess != savedShininess)
	{
		glUniform1f(material_shininessPos, globalMaterial.shininess);
		savedShininess = globalMaterial.shininess;
	}
}

- (void)dealloc
{
#if defined(TARGET_OS_MAC) && defined(DEBUG) && !defined(SDL)
    if (![[RenderViewController sharedController] loadingWindow] && [NSThread isMainThread]) fatal("doing things on main instead of render thread");
#endif

	assert(name);
	if (name)
	{
		NSString *key = defines ? [name stringByAppendingString:defines] : name;

		if (namedObjects->count([key UTF8String]))
		{
			MutableArray *cachedObjects = (*namedObjects)[[key UTF8String]];

			for (unsigned int i = 0; i < cachedObjects->size(); i++)
				if ((*cachedObjects)[i] == self)
					cachedObjects->erase(cachedObjects->begin() + i);
		}
	}

	if (currentShader == self)
	{
		currentShader = nil;
		glUseProgram(0);
	}

	glDeleteProgram(shaderName);
	[uniformLocations release];
	[uniformValues release];
	[vertexShader release];
	[fragmentShader release];
	[name release];
	[defines release];

	[super dealloc];
}

@end
