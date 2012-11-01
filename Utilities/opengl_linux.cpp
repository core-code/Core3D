//#include <X11/Xlib.h>
//#include <X11/Xutil.h>
//#include <X11/Xmd.h>

#include <GL/gl.h>
#include <GL/glx.h>

#include <GL/glext.h>
#include <GL/glxext.h>
#include <stdlib.h>
#include <stdio.h>

// opengl 1.3
//PFNGLACTIVETEXTUREPROC glActiveTexture = 0;
//PFNGLCOMPRESSEDTEXIMAGE2DPROC glCompressedTexImage2D = 0;
//PFNGLCOMPRESSEDTEXSUBIMAGE2DPROC glCompressedTexSubImage2D = 0;
// opengl 1.5
PFNGLGENBUFFERSPROC glGenBuffers = 0;
PFNGLBINDBUFFERPROC glBindBuffer = 0;
PFNGLBUFFERDATAPROC glBufferData = 0;
PFNGLMAPBUFFERPROC glMapBuffer = 0;
PFNGLUNMAPBUFFERPROC glUnmapBuffer = 0;
PFNGLDELETEBUFFERSPROC glDeleteBuffers = 0;
// opengl 2.0
PFNGLCREATESHADERPROC glCreateShader = 0;
PFNGLSHADERSOURCEPROC glShaderSource = 0;
PFNGLCOMPILESHADERPROC glCompileShader = 0;
PFNGLGETSHADERIVPROC glGetShaderiv = 0;
PFNGLDELETESHADERPROC glDeleteShader = 0;
PFNGLCREATEPROGRAMPROC glCreateProgram = 0;
PFNGLATTACHSHADERPROC glAttachShader = 0;
PFNGLLINKPROGRAMPROC glLinkProgram = 0;
PFNGLGETPROGRAMIVPROC glGetProgramiv = 0;
PFNGLUSEPROGRAMPROC glUseProgram = 0;
PFNGLDELETEPROGRAMPROC glDeleteProgram = 0;
PFNGLGETUNIFORMLOCATIONPROC glGetUniformLocation = 0;
PFNGLUNIFORM1IPROC glUniform1i = 0;
PFNGLUNIFORM1IVPROC glUniform1iv = 0;
PFNGLUNIFORM1FPROC glUniform1f = 0;
PFNGLUNIFORM2FVPROC glUniform2fv = 0;
PFNGLUNIFORM3FPROC glUniform3f = 0;
PFNGLUNIFORM3FVPROC glUniform3fv = 0;
PFNGLUNIFORM4FVPROC glUniform4fv = 0;
PFNGLUNIFORMMATRIX4FVPROC glUniformMatrix4fv;
PFNGLUNIFORMMATRIX3FVPROC glUniformMatrix3fv;
PFNGLGETPROGRAMINFOLOGPROC glGetProgramInfoLog = 0;
PFNGLGETSHADERINFOLOGPROC glGetShaderInfoLog = 0;
PFNGLDRAWBUFFERSPROC glDrawBuffers = 0;
//PFNGLBLENDCOLORPROC glBlendColor = 0;
PFNGLVERTEXATTRIBPOINTERPROC glVertexAttribPointer = 0;
PFNGLENABLEVERTEXATTRIBARRAYPROC glEnableVertexAttribArray = 0;
PFNGLENABLEVERTEXATTRIBARRAYPROC glDisableVertexAttribArray = 0;
PFNGLBINDATTRIBLOCATIONPROC glBindAttribLocation = 0;


// GL_EXT_framebuffer_object
PFNGLGENFRAMEBUFFERSEXTPROC glGenFramebuffersEXT = 0;
PFNGLBINDFRAMEBUFFEREXTPROC glBindFramebufferEXT = 0;
PFNGLDELETEFRAMEBUFFERSEXTPROC glDeleteFramebuffersEXT = 0;
PFNGLFRAMEBUFFERTEXTURE2DEXTPROC glFramebufferTexture2DEXT = 0;
PFNGLCHECKFRAMEBUFFERSTATUSEXTPROC glCheckFramebufferStatusEXT = 0;
PFNGLFRAMEBUFFERRENDERBUFFEREXTPROC glFramebufferRenderbufferEXT = 0;
PFNGLGENRENDERBUFFERSEXTPROC glGenRenderbuffersEXT = 0;
PFNGLBINDRENDERBUFFEREXTPROC glBindRenderbufferEXT = 0;
PFNGLRENDERBUFFERSTORAGEEXTPROC glRenderbufferStorageEXT = 0;
PFNGLGENERATEMIPMAPEXTPROC glGenerateMipmap = 0;

static inline void oglwin32_fatal(const char *err) {printf ("%s", err); exit(1); }


void init_opengl_function_pointers()
{
    glBindAttribLocation = (PFNGLBINDATTRIBLOCATIONPROC)glXGetProcAddress((unsigned char *)"glBindAttribLocation");
	if (!glBindAttribLocation) oglwin32_fatal("glBindAttribLocation is NULL");
    glVertexAttribPointer = (PFNGLVERTEXATTRIBPOINTERPROC)glXGetProcAddress((unsigned char *)"glVertexAttribPointer");
	if (!glVertexAttribPointer) oglwin32_fatal("glVertexAttribPointer is NULL");
    glEnableVertexAttribArray = (PFNGLENABLEVERTEXATTRIBARRAYPROC)glXGetProcAddress((unsigned char *)"glEnableVertexAttribArray");
	if (!glEnableVertexAttribArray) oglwin32_fatal("glEnableVertexAttribArray is NULL");
    glDisableVertexAttribArray = (PFNGLENABLEVERTEXATTRIBARRAYPROC)glXGetProcAddress((unsigned char *)"glDisableVertexAttribArray");
	if (!glDisableVertexAttribArray) oglwin32_fatal("glVertexAttribPointer is NULL");
	//glCompressedTexSubImage2D = (PFNGLCOMPRESSEDTEXSUBIMAGE2DPROC)glXGetProcAddress((unsigned char *)"glCompressedTexSubImage2D");
	if (!glCompressedTexSubImage2D) oglwin32_fatal("glCompressedTexSubImage2D is NULL");
	//glCompressedTexImage2D = (PFNGLCOMPRESSEDTEXIMAGE2DPROC)glXGetProcAddress((unsigned char *)"glCompressedTexImage2D");
	if (!glCompressedTexImage2D) oglwin32_fatal("glCompressedTexImage2D is NULL");
	glGenBuffers = (PFNGLGENBUFFERSPROC)glXGetProcAddress((unsigned char *)"glGenBuffers");
	if (!glGenBuffers) oglwin32_fatal("glGenBuffers is NULL");
	glBindBuffer = (PFNGLBINDBUFFERPROC)glXGetProcAddress((unsigned char *)"glBindBuffer");
	if (!glBindBuffer) oglwin32_fatal("glBindBuffer is NULL");
	glBufferData = (PFNGLBUFFERDATAPROC)glXGetProcAddress((unsigned char *)"glBufferData");
	if (!glBufferData) oglwin32_fatal("glBufferData is NULL");
	glMapBuffer = (PFNGLMAPBUFFERPROC)glXGetProcAddress((unsigned char *)"glMapBuffer");
	if (!glMapBuffer) oglwin32_fatal("glMapBuffer is NULL");
	glUnmapBuffer = (PFNGLUNMAPBUFFERPROC)glXGetProcAddress((unsigned char *)"glUnmapBuffer");
	if (!glUnmapBuffer) oglwin32_fatal("glUnmapBuffer is NULL");
	glDeleteBuffers = (PFNGLDELETEBUFFERSPROC)glXGetProcAddress((unsigned char *)"glDeleteBuffers");
	if (!glDeleteBuffers) oglwin32_fatal("glDeleteBuffers is NULL");
	glCreateShader = (PFNGLCREATESHADERPROC)glXGetProcAddress((unsigned char *)"glCreateShader");
	if (!glCreateShader) oglwin32_fatal("glCreateShader is NULL");
	glShaderSource = (PFNGLSHADERSOURCEPROC)glXGetProcAddress((unsigned char *)"glShaderSource");
	if (!glShaderSource) oglwin32_fatal("glShaderSource is NULL");
	glCompileShader = (PFNGLCOMPILESHADERPROC)glXGetProcAddress((unsigned char *)"glCompileShader");
	if (!glCompileShader) oglwin32_fatal("glCompileShader is NULL");
	glGetShaderiv = (PFNGLGETSHADERIVPROC)glXGetProcAddress((unsigned char *)"glGetShaderiv");
	if (!glGetShaderiv) oglwin32_fatal("glGetShaderiv is NULL");
	glDeleteShader = (PFNGLDELETESHADERPROC)glXGetProcAddress((unsigned char *)"glDeleteShader");
	if (!glDeleteShader) oglwin32_fatal("glDeleteShader is NULL");
	glCreateProgram = (PFNGLCREATEPROGRAMPROC)glXGetProcAddress((unsigned char *)"glCreateProgram");
	if (!glCreateProgram) oglwin32_fatal("glCreateProgram is NULL");
	glAttachShader = (PFNGLATTACHSHADERPROC)glXGetProcAddress((unsigned char *)"glAttachShader");
	if (!glAttachShader) oglwin32_fatal("glAttachShader is NULL");
	glLinkProgram = (PFNGLLINKPROGRAMPROC)glXGetProcAddress((unsigned char *)"glLinkProgram");
	if (!glLinkProgram) oglwin32_fatal("glLinkProgram is NULL");
	glGetProgramiv = (PFNGLGETPROGRAMIVPROC)glXGetProcAddress((unsigned char *)"glGetProgramiv");
	if (!glGetProgramiv) oglwin32_fatal("glGetProgramiv is NULL");
	glUseProgram = (PFNGLUSEPROGRAMPROC)glXGetProcAddress((unsigned char *)"glUseProgram");
	if (!glUseProgram) oglwin32_fatal("glUseProgram is NULL");
	glGetUniformLocation = (PFNGLGETUNIFORMLOCATIONPROC)glXGetProcAddress((unsigned char *)"glGetUniformLocation");
	if (!glGetUniformLocation) oglwin32_fatal("glGetUniformLocation is NULL");
	glUniform1i = (PFNGLUNIFORM1IPROC)glXGetProcAddress((unsigned char *)"glUniform1i");
	if (!glUniform1i) oglwin32_fatal("glUniform1i is NULL");
	glUniform1iv = (PFNGLUNIFORM1IVPROC)glXGetProcAddress((unsigned char *)"glUniform1iv");
	if (!glUniform1iv) oglwin32_fatal("glUniform1iv is NULL");
	glUniform1f = (PFNGLUNIFORM1FPROC)glXGetProcAddress((unsigned char *)"glUniform1f");
	if (!glUniform1f) oglwin32_fatal("glUniform1f is NULL");
    glUniform2fv = (PFNGLUNIFORM2FVPROC)glXGetProcAddress((unsigned char *)"glUniform2fv");
	if (!glUniform2fv) oglwin32_fatal("glUniform2fv is NULL");

	glUniform3f = (PFNGLUNIFORM3FPROC)glXGetProcAddress((unsigned char *)"glUniform3f");
	if (!glUniform3f) oglwin32_fatal("glUniform3f is NULL");
	glUniform3fv = (PFNGLUNIFORM3FVPROC)glXGetProcAddress((unsigned char *)"glUniform3fv");
	if (!glUniform3fv) oglwin32_fatal("glUniform3fv is NULL");
	glUniform4fv = (PFNGLUNIFORM4FVPROC)glXGetProcAddress((unsigned char *)"glUniform4fv");
	if (!glUniform4fv) oglwin32_fatal("glUniform4fv is NULL");
	glUniformMatrix4fv = (PFNGLUNIFORMMATRIX4FVPROC)glXGetProcAddress((unsigned char *)"glUniformMatrix4fv");
	if (!glUniformMatrix4fv) oglwin32_fatal("glUniformMatrix4fv is NULL");
    glUniformMatrix3fv = (PFNGLUNIFORMMATRIX3FVPROC)glXGetProcAddress((unsigned char *)"glUniformMatrix3fv");
	if (!glUniformMatrix3fv) oglwin32_fatal("glUniformMatrix3fv is NULL");
	glGenFramebuffersEXT = (PFNGLGENFRAMEBUFFERSEXTPROC)glXGetProcAddress((unsigned char *)"glGenFramebuffersEXT");
	if (!glGenFramebuffersEXT) oglwin32_fatal("glGenFramebuffersEXT is NULL");
	glGenRenderbuffersEXT = (PFNGLGENRENDERBUFFERSEXTPROC)glXGetProcAddress((unsigned char *)"glGenRenderbuffersEXT");
	if (!glGenRenderbuffersEXT) oglwin32_fatal("glGenRenderbuffersEXT is NULL");
	glBindFramebufferEXT = (PFNGLBINDFRAMEBUFFEREXTPROC)glXGetProcAddress((unsigned char *)"glBindFramebufferEXT");
	if (!glBindFramebufferEXT) oglwin32_fatal("glBindFramebufferEXT is NULL");
	glDeleteFramebuffersEXT = (PFNGLDELETEFRAMEBUFFERSEXTPROC)glXGetProcAddress((unsigned char *)"glDeleteFramebuffersEXT");
	if (!glDeleteFramebuffersEXT) oglwin32_fatal("glDeleteFramebuffersEXT is NULL");
	glFramebufferTexture2DEXT = (PFNGLFRAMEBUFFERTEXTURE2DEXTPROC)glXGetProcAddress((unsigned char *)"glFramebufferTexture2DEXT");
	if (!glFramebufferTexture2DEXT) oglwin32_fatal("glFramebufferTexture2DEXT is NULL");
	glBindRenderbufferEXT = (PFNGLBINDRENDERBUFFEREXTPROC)glXGetProcAddress((unsigned char *)"glBindRenderbufferEXT");
	if (!glBindRenderbufferEXT) oglwin32_fatal("glBindRenderbufferEXT is NULL");
	glRenderbufferStorageEXT = (PFNGLRENDERBUFFERSTORAGEEXTPROC)glXGetProcAddress((unsigned char *)"glRenderbufferStorageEXT");
	if (!glRenderbufferStorageEXT) oglwin32_fatal("glRenderbufferStorageEXT is NULL");
	glFramebufferRenderbufferEXT = (PFNGLFRAMEBUFFERRENDERBUFFEREXTPROC)glXGetProcAddress((unsigned char *)"glFramebufferRenderbufferEXT");
	if (!glFramebufferRenderbufferEXT) oglwin32_fatal("glFramebufferRenderbufferEXT is NULL");
	glCheckFramebufferStatusEXT = (PFNGLCHECKFRAMEBUFFERSTATUSEXTPROC)glXGetProcAddress((unsigned char *)"glCheckFramebufferStatusEXT");
	if (!glCheckFramebufferStatusEXT) oglwin32_fatal("glCheckFramebufferStatusEXT is NULL");
	glDrawBuffers = (PFNGLDRAWBUFFERSPROC)glXGetProcAddress((unsigned char *)"glDrawBuffers");
	if (!glDrawBuffers) oglwin32_fatal("glDrawBuffers is NULL");
	glGetProgramInfoLog = (PFNGLGETPROGRAMINFOLOGPROC)glXGetProcAddress((unsigned char *)"glGetProgramInfoLog");
	if (!glGetProgramInfoLog) oglwin32_fatal("glGetProgramInfoLog is NULL");
	glGetShaderInfoLog = (PFNGLGETSHADERINFOLOGPROC)glXGetProcAddress((unsigned char *)"glGetShaderInfoLog");
	if (!glGetShaderInfoLog) oglwin32_fatal("glGetShaderInfoLog is NULL");
	//glActiveTexture = (PFNGLACTIVETEXTUREARBPROC)glXGetProcAddress((unsigned char *)"glActiveTexture");
	if (!glActiveTexture) oglwin32_fatal("glActiveTexture is NULL");
	glGenerateMipmap = (PFNGLGENERATEMIPMAPEXTPROC)glXGetProcAddress((unsigned char *)"glGenerateMipmap");
	if (!glGenerateMipmap)
	{
        	glGenerateMipmap = (PFNGLGENERATEMIPMAPEXTPROC)glXGetProcAddress((unsigned char *)"glGenerateMipmapEXT");
	        if (!glGenerateMipmap)
        	    oglwin32_fatal("glGenerateMipmap is NULL");
	}
	glDeleteProgram = (PFNGLDELETEPROGRAMPROC)glXGetProcAddress((unsigned char *)"glDeleteProgram");
	if (!glDeleteProgram) oglwin32_fatal("glDeleteProgram is NULL");
//	glBlendColor = (PFNGLBLENDCOLORPROC)glXGetProcAddress((unsigned char *)"glBlendColor");
	if (!glBlendColor) oglwin32_fatal("glBlendColor is NULL");
}


