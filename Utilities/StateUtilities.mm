#import "Core3D.h"

#undef glBlendFunc
#undef glLineWidth
#undef glPolygonOffset
#undef glBlendColor
#undef glViewport
#undef glEnableVertexAttribArray
#undef glDisableVertexAttribArray
#undef glEnable
#undef glDisable
#undef glDepthMask

static GLfloat storedFactor = 0.0f;
static GLfloat storedUnits = 0.0f;
static GLenum storedS = GL_ONE;
static GLenum storedD = GL_ONE_MINUS_SRC_ALPHA;
static GLfloat storedPointSize = 1;
static GLfloat storedLineWidth = 1;
static requirementEnum stored[3] = {kNeedDisabled, kNeedDisabled, kNeedDisabled};
static GLsizei storedWidth = 0;
static GLsizei storedHeight = 0;
static GLint storedX = 0;
static GLint storedY = 0;
static vector4f storedBlendColor = vector4f(0.0f, 0.0f, 0.0f, 0.0f);
static bool storedBlend = 0;
static bool storedParticle = 0;
static bool storedCull = 1;
static bool storedDepthTest = 1;
static bool storedDepthWrite = 1;

static GLfloat smoothLineWidthRange[2] = {0.1, 4.0};

void ResetState()
{
	storedFactor = 0.0f;
	storedUnits = 0.0f;

	storedS = GL_ONE;
	storedD = GL_ONE_MINUS_SRC_ALPHA;
	storedPointSize = 1;
	storedLineWidth = 1;
	stored[0] = kNeedDisabled;
	stored[1] = kNeedDisabled;
	stored[2] = kNeedDisabled;
    storedBlendColor = vector4f(0.0f, 0.0f, 0.0f, 0.0f);

	storedX = storedY = storedWidth = storedHeight = 0;
    
    storedBlend = 0;
    storedParticle= 0;
    storedCull = 1;
    storedDepthTest = 1;
    storedDepthWrite = 1;

#ifdef GL_ES_VERSION_2_0
    glGetFloatv(GL_ALIASED_LINE_WIDTH_RANGE, smoothLineWidthRange);
#else
    glGetFloatv(GL_SMOOTH_LINE_WIDTH_RANGE, smoothLineWidthRange);
#endif
    if (smoothLineWidthRange[0] < 0.1)
        smoothLineWidthRange[0] = 0.1;
#ifndef TARGET_OS_MAC
    if (globalInfo.gpuVendor == kVendorATI) // work around a bad catalyst driver bug, line width >= 2.0 fucks everything. they don't care => fuck 'em
        smoothLineWidthRange[1] = 1.99;
#endif

	//NSLog(@"reset state");
    
    glDisable(GL_BLEND);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glDepthMask(GL_TRUE);

#ifndef GL_ES_VERSION_2_0    
    if ($defaulti(kFsaaKey))
        glEnable(GL_MULTISAMPLE);
    
    glEnable(GL_LINE_SMOOTH);
    glEnable(GL_VERTEX_PROGRAM_POINT_SIZE);
    glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
    glDisable(GL_POINT_SPRITE);
    
    if (!globalInfo.modernOpenGL)
        glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
#endif
    
//#ifdef __APPLE__
//    if (globalInfo.defaultVAOName)
//        glDeleteVertexArrays(1, &globalInfo.defaultVAOName);
//    glGenVertexArrays(1, &globalInfo.defaultVAOName);
//    glBindVertexArray(globalInfo.defaultVAOName);
//#endif
}

void DeleteState()
{
//#ifdef __APPLE__
//    if (globalInfo.defaultVAOName)
//        glDeleteVertexArrays(1, &globalInfo.defaultVAOName);
//#endif
}

GLfloat getLineWidth() { return storedLineWidth; }

void myLineWidth(const GLfloat width)
{
	float ourWidth = CLAMP(width, smoothLineWidthRange[0], smoothLineWidthRange[1]);
    
	if (storedLineWidth != ourWidth)
	{
		glLineWidth(ourWidth);

		storedLineWidth = ourWidth;
	}
}

void myBlendFunc(const GLenum s, const GLenum d)
{
	if ((storedS != s) || (storedD != d))
	{
		glBlendFunc(s, d);
		storedS = s;
		storedD = d;
	}
}

void myPolygonOffset(const GLfloat factor, const GLfloat units )
{
	if ((storedFactor != factor) || (storedUnits != units))
	{
		glPolygonOffset(factor, units);
		storedFactor = factor;
		storedUnits = units;
	}
}

void myViewport(const GLint x, const GLint y, const GLsizei width, const GLsizei height)
{
	if ((storedX != x) || (storedY != y) || (storedWidth != width) || (storedHeight != height))
	{
		glViewport(x, y, width, height);

		storedX = x;
		storedY = y;
		storedWidth = width;
		storedHeight = height;
	}
}

void myEnableVertexAttribArray(const GLuint index)
{
    assert(index < MAX_ATTRIBS);
    if (stored[index] != kNeedEnabled)
    {
        glEnableVertexAttribArray(index);
        stored[index] = kNeedEnabled;
    }
}

void myDisableVertexAttribArray(const GLuint index)
{
    assert(index < MAX_ATTRIBS);
    if (stored[index] != kNeedDisabled)
    {
        glDisableVertexAttribArray(index);
        stored[index] = kNeedDisabled;
    }
}

void myEnableBlendParticleCullDepthtestDepthwrite(const bool blend, const bool particle, const bool cull, const bool depthTest, const bool depthWrite)
{
    if (storedBlend != blend)
	{
		storedBlend = blend;
        
		if (blend == YES)     {	glEnable(GL_BLEND); }
		else                  {	glDisable(GL_BLEND);  }
	}
 
    
#if !defined(GL_ES_VERSION_2_0)
    if (storedParticle != particle && !globalInfo.modernOpenGL)
	{
		storedParticle = particle;
        
		if (particle == YES)  {	glEnable(GL_POINT_SPRITE); }
		else                  {	glDisable(GL_POINT_SPRITE);  }
	}
#endif
    
  
	if (storedCull != cull)
	{
		storedCull = cull;
        
		if (cull == YES)      {	glEnable(GL_CULL_FACE); }
		else                  {	glDisable(GL_CULL_FACE);  }
	}
    
    
	if (storedDepthTest != depthTest)
	{
		storedDepthTest = depthTest;
        
		if (depthTest == YES) {	glEnable(GL_DEPTH_TEST); }
		else                  {	glDisable(GL_DEPTH_TEST);  }
	}
    
	if (storedDepthWrite != depthWrite)
	{
		storedDepthWrite = depthWrite;
        
		if (depthWrite == YES) {glDepthMask(GL_TRUE); }
		else                  {	glDepthMask(GL_FALSE);  }
	}
}


void myClientStateVTN(const requirementEnum vertexneed, const requirementEnum textureneed, const requirementEnum normalneed)
{
    [VBO unbind];
    
    if (stored[0] != vertexneed)
	{
		stored[0] = vertexneed;

		if (vertexneed == kNeedEnabled)     {	glEnableVertexAttribArray(VERTEX_ARRAY); }
		else                                {	glDisableVertexAttribArray(VERTEX_ARRAY); }
	}


	if (stored[1] != textureneed)
	{
		stored[1] = textureneed;

		if (textureneed == kNeedEnabled)	{	glEnableVertexAttribArray(TEXTURE_COORD_ARRAY); }
		else								{	glDisableVertexAttribArray(TEXTURE_COORD_ARRAY); }
	}


	if (stored[2] != normalneed)
	{
		stored[2] = normalneed;

		if (normalneed == kNeedEnabled)     {	glEnableVertexAttribArray(NORMAL_ARRAY); }
		else                                {	glDisableVertexAttribArray(NORMAL_ARRAY); }
	}
}

void myBlendColor(const GLfloat red, const GLfloat green, const GLfloat blue, const GLfloat alpha)
{
    if (storedBlendColor[0] != red || storedBlendColor[1] != green || storedBlendColor[2] != blue || storedBlendColor[3] != alpha)
    {
        storedBlendColor = vector4f(red, green, blue, alpha);
        glBlendColor(red, green, blue, alpha);
    }
}
//#define DEBUG_ALIGNMENT 1
//void myNormalPointer(const GLenum type, const GLsizei stride, const GLvoid *pointer)
//{
//	static GLenum storedType;
//	static GLsizei storedStride;
//	static const GLvoid *storedPointer;
//
//	if ((storedType != type) || (storedStride != stride) || (storedPointer != pointer))
//	{
//		glNormalPointer(type, stride, pointer);
//		storedType = type;
//		storedStride = stride;
//		storedPointer = pointer;
//	}
//	else
//		glNormalPointer(storedType, storedStride, storedPointer); // TODO: why do we have to do redundant changes here??
//
//#ifdef DEBUG_ALIGNMENT
//	if (type == GL_SHORT)
//	{
//		if ((long)pointer % 2 != 0)
//			fatal("sucky alignment");
//	}
//	else if ((type == GL_FLOAT) || (type == GL_INT))
//	{
//		if ((long)pointer % 4 != 0)
//			fatal("sucky alignment");
//	}
//	else if (type == GL_DOUBLE)
//	{
//		if ((long)pointer % 8 != 0)
//			fatal("sucky alignment");
//	}
//	else
//		fatal("invalid type");
//#endif
//}
//
//void myVertexPointer(const GLint size, const GLenum type, const GLsizei stride, const GLvoid *pointer)
//{
//	static GLint storedSize;
//	static GLenum storedType;
//	static GLsizei storedStride;
//	static const GLvoid *storedPointer;
//
//	if ((storedSize != size) || (storedType != type) || (storedStride != stride) || (storedPointer != pointer))
//	{
//		glVertexPointer(size, type, stride, pointer);
//		storedSize = size;
//		storedType = type;
//		storedStride = stride;
//		storedPointer = pointer;
//
//		printf(" just set");
//		GLuint bla;
//		GLvoid *ente;
//		glGetIntegerv(GL_VERTEX_ARRAY_SIZE, (GLint *) &bla);
//		printf(" GL_VERTEX_ARRAY_SIZE %i ", bla);
//		glGetIntegerv(GL_VERTEX_ARRAY_TYPE, (GLint *) &bla);
//		printf(" GL_VERTEX_ARRAY_TYPE %i ", bla);
//		glGetIntegerv(GL_VERTEX_ARRAY_STRIDE, (GLint *) &bla);
//		printf(" GL_VERTEX_ARRAY_STRIDE %i", bla);
//		glGetPointerv(GL_VERTEX_ARRAY_POINTER, &ente);
//		printf(" GL_VERTEX_ARRAY_POINTER %p %p \n\n", ente, pointer);
//	}
//	else
//	{
//		printf(" should be same!:" );
//
//		GLint bla;
//		GLvoid *ente;
//		glGetIntegerv(GL_VERTEX_ARRAY_SIZE, (GLint *) &bla);
////		if (bla != size)
//			printf(" GL_VERTEX_ARRAY_SIZE %i %i ", bla, size);
//		glGetIntegerv(GL_VERTEX_ARRAY_TYPE, (GLint *) &bla);
////		if (bla != type)
//			printf(" GL_VERTEX_ARRAY_TYPE %i %i ", bla, type);
//		glGetIntegerv(GL_VERTEX_ARRAY_STRIDE, (GLint *) &bla);
////		if (bla != stride)
//			printf(" GL_VERTEX_ARRAY_STRIDE %i %i", bla, stride);
//		glGetPointerv(GL_VERTEX_ARRAY_POINTER, &ente);
////		if (ente != pointer)
//
//			printf(" GL_VERTEX_ARRAY_POINTER %p %p \n\n", ente, pointer);
//
//		//glVertexPointer(storedSize, storedType, storedStride, storedPointer);
//	}
//
//#ifdef DEBUG_ALIGNMENT
//	if (type == GL_SHORT)
//	{
//		if ((long)pointer % 2 != 0)
//			fatal("sucky alignment");
//	}
//	else if ((type == GL_FLOAT) || (type == GL_INT))
//	{
//		if ((long)pointer % 4 != 0)
//			fatal("sucky alignment")
//	}
//	else if (type == GL_DOUBLE)
//	{
//		if ((long)pointer % 8 != 0)
//			fatal("sucky alignment")
//	}
//	else
//		fatal("invalid type");
//#endif
//}
//
//void myTexCoordPointer(const GLint size, const GLenum type, const GLsizei stride, const GLvoid *pointer)
//{
//	static GLint storedSize;
//	static GLenum storedType;
//	static GLsizei storedStride;
//	static GLvoid *storedPointer;
//
//	if ((storedSize != size) || (storedType != type) || (storedStride != stride) || (storedPointer != pointer))
//	{
//		glTexCoordPointer(size, type, stride, pointer);
//		storedSize = size;
//		storedType = type;
//		storedStride = stride;
//		storedPointer = (GLvoid *) pointer;
//	}
//	else
//		glTexCoordPointer(size, type, stride, pointer);
//
//#ifdef DEBUG_ALIGNMENT
//	if (type == GL_SHORT)
//	{
//		if ((long)pointer % 2 != 0)
//			fatal("sucky alignment");
//	}
//	else if ((type == GL_FLOAT) || (type == GL_INT))
//	{
//		if ((long)pointer % 4 != 0)
//			fatal("sucky alignment")
//	}
//	else if (type == GL_DOUBLE)
//	{
//		if ((long)pointer % 8 != 0)
//			fatal("sucky alignment")
//	}
//	else
//		fatal("invalid type");
//#endif
//}
