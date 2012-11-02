#import "Utilities.h"

#ifdef __APPLE__
#import <snappy/snappy-c.h>
#else
#import <snappy-c.h>
#endif

void * UncompressedBufferFromSNZFile(FILE *f)
{
    size_t fileSize;
    size_t result;
    
    fseek(f, 0, SEEK_END);
    fileSize = ftell(f);
    rewind(f);
    
    char *compressedData = (char *)malloc(fileSize+4);
    assert(compressedData);
    
    result = fread(compressedData, fileSize, 1, f);
    assert(result == 1);
    
    
    
    size_t uncompressedSize = 0;
    
    
    if( snappy_uncompressed_length(compressedData, fileSize, &uncompressedSize) != SNAPPY_OK ) {
        fatal("Can't calculate the uncompressed length!\n");
    }
    
    assert(uncompressedSize);
    
    char *buf = (char *)malloc(uncompressedSize);
    assert(buf);
    
    
    //    printf("Recalculated uncompressed length=%lu\n",(unsigned long)uncompressedSize);
    
    
    if( snappy_uncompress(compressedData, fileSize, buf, &uncompressedSize) != SNAPPY_OK ) {
        fatal("Can't uncompress the file!\n");
    }
    else
    {
        //   printf("Uncompressed! true length %lu\n", (unsigned long)uncompressedSize);
    }
    
    free(compressedData);
    return buf;
}

void DrawARFullScreenQuad(const short textureWidth, const short textureHeight)
{
    const int screenWidth = [currentRenderPass frame].size.width;
    const int screenHeight = [currentRenderPass frame].size.height;
    
    const float screenAR = (float)screenWidth / (float)screenHeight;
    const float textureAR = (float)textureWidth / (float)textureHeight;
    // if screen wider, scale so that we fill the height, else if texture wider, scale so that we fill the width
    const float scaleFactor = (screenAR > textureAR) ? ((float)screenHeight / (float)textureHeight) : ((float)screenWidth / (float)textureWidth);
    
    DrawCenteredScreenQuad((float)textureWidth * scaleFactor, (float)textureHeight * scaleFactor);
}

void DrawCenteredScreenQuad(const short textureWidth, const short textureHeight)
{
    const int screenWidth = [currentRenderPass frame].size.width;
    const int screenHeight = [currentRenderPass frame].size.height;
    
    
    const int remainingWidth = screenWidth - textureWidth;
    const int remainingHeight = screenHeight - textureHeight;
    const int remainingWidthHalf = remainingWidth / 2;
    const int remainingHeightHalf = remainingHeight / 2;
    
	DrawQuadWithCoordinates(    remainingWidthHalf,                 remainingHeightHalf,
                            screenWidth - remainingWidthHalf,   remainingHeightHalf,
                            screenWidth - remainingWidthHalf,   screenHeight - remainingHeightHalf,
                            remainingWidthHalf,                 screenHeight - remainingHeightHalf);
}

void DrawQuadWithCoordinates(const GLshort x1, const GLshort y1, const GLshort x2, const GLshort y2, const GLshort x3, const GLshort y3, const GLshort x4, const GLshort y4)
{
    const int screenWidth = [currentRenderPass frame].size.width;
    const int screenHeight = [currentRenderPass frame].size.height;
    
	matrix44f_c orthographicMatrix;
	matrix_orthographic_RH(orthographicMatrix, 0.0f, (float)screenWidth, 0.0f, (float)screenHeight, -1.0f, 1.0f, cml::z_clip_neg_one);
    
    [currentShader prepareWithModelViewMatrix:cml::identity_transform<4,4>() andProjectionMatrix:orthographicMatrix];
    
    
    
	const GLshort vertices[] = {    x1, y1,
        x2, y2,
        x3, y3,
        x4, y4};
	const GLshort texCoords[] = {0, 0,  1, 0,  1, 1,  0, 1};
	const GLushort indices[] = {0,1,3, 1,2,3};
    
	myClientStateVTN(kNeedEnabled, kNeedEnabled, kNeedDisabled);
    
	glVertexAttribPointer(TEXTURE_COORD_ARRAY,  2, GL_SHORT, GL_FALSE, 0, texCoords);
	glVertexAttribPointer(VERTEX_ARRAY,         2, GL_SHORT, GL_FALSE, 0, vertices);
    
    
	glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, indices);
    
    globalInfo.drawCalls++;
    /*DRAW_CALL*/
}

void DrawQuadWithCoordinatesRotation(const GLshort x1, const GLshort y1, const GLshort x2, const GLshort y2, const GLshort x3, const GLshort y3, const GLshort x4, const GLshort y4, const GLfloat rotation)
{
    const int screenWidth = [currentRenderPass frame].size.width;
    const int screenHeight = [currentRenderPass frame].size.height;
    
	matrix44f_c orthographicMatrix;
	matrix_orthographic_RH(orthographicMatrix, 0.0f, (float)screenWidth, 0.0f, (float)screenHeight, -1.0f, 1.0f, cml::z_clip_neg_one);
    
    matrix44f_c m = cml::identity_transform<4,4>();
	matrix44f_c mt;
	matrix_translation(mt, vector3f(screenWidth/2, screenHeight/2, 0.0));
	m *= mt;
    matrix_rotate_about_local_z(m, cml::rad(rotation));
    matrix44f_c mt2;
	matrix_translation(mt2, vector3f(-screenWidth/2, -screenHeight/2, 0.0));
	m *= mt2;

    [currentShader prepareWithModelViewMatrix:m andProjectionMatrix:orthographicMatrix];
    
    
    
	const GLshort vertices[] = {    x1, y1,
        x2, y2,
        x3, y3,
        x4, y4};
	const GLshort texCoords[] = {0, 0,  1, 0,  1, 1,  0, 1};
	const GLushort indices[] = {0,1,3, 1,2,3};
    
	myClientStateVTN(kNeedEnabled, kNeedEnabled, kNeedDisabled);
    
	glVertexAttribPointer(TEXTURE_COORD_ARRAY,  2, GL_SHORT, GL_FALSE, 0, texCoords);
	glVertexAttribPointer(VERTEX_ARRAY,         2, GL_SHORT, GL_FALSE, 0, vertices);
    
    
	glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, indices);
    
    globalInfo.drawCalls++;
    /*DRAW_CALL*/
}

char AABoxInFrustum(const float frustum[6][4],
                    const float x, const float y, const float z,
                    const float ex, const float ey, const float ez) // adapted code from glm and lighthouse tutorial
{
	int p;
	int result = kInside, out,in;	// TODO: optimiziation: http://www.lighthouse3d.com/opengl/viewfrustum/index.php?gatest3
    
	for(p = 0; p < 6; p++)
	{
		out = 0;
		in = 0;
        
		if (frustum[p][0]*(x-ex) + frustum[p][1]*(y-ey) + frustum[p][2]*(z-ez) + frustum[p][3] < 0) out++; else in++;
		if (frustum[p][0]*(x+ex) + frustum[p][1]*(y-ey) + frustum[p][2]*(z-ez) + frustum[p][3] < 0) out++; else in++;
		if (frustum[p][0]*(x-ex) + frustum[p][1]*(y+ey) + frustum[p][2]*(z-ez) + frustum[p][3] < 0) out++; else in++;
		if (frustum[p][0]*(x+ex) + frustum[p][1]*(y+ey) + frustum[p][2]*(z-ez) + frustum[p][3] < 0) out++; else in++;
		if (frustum[p][0]*(x-ex) + frustum[p][1]*(y-ey) + frustum[p][2]*(z+ez) + frustum[p][3] < 0) out++; else in++;
		if (frustum[p][0]*(x+ex) + frustum[p][1]*(y-ey) + frustum[p][2]*(z+ez) + frustum[p][3] < 0) out++; else in++;
		if (frustum[p][0]*(x-ex) + frustum[p][1]*(y+ey) + frustum[p][2]*(z+ez) + frustum[p][3] < 0) out++; else in++;
		if (frustum[p][0]*(x+ex) + frustum[p][1]*(y+ey) + frustum[p][2]*(z+ez) + frustum[p][3] < 0) out++; else in++;
        
		if (!in)			// if all corners are out
			return (kOutside);
		else if (out)		// if some corners are out and others are in
			result = kIntersecting;
	}
    
	return(result);
}



#ifdef WIN32
#include <windows.h>
LARGE_INTEGER freq;
void NanosecondsInit()
{
	QueryPerformanceFrequency(&freq);
}
uint64_t GetNanoseconds()
{
	LARGE_INTEGER ntime;
    
	assert(freq.QuadPart != 0);
	QueryPerformanceCounter(&ntime);
    
	return (uint64_t)((double)ntime.QuadPart * 1000.0 /((double)freq.QuadPart / (1000.0 * 1000.0)));
}

#elif defined(__APPLE__)
mach_timebase_info_data_t sTimebaseInfo;
void NanosecondsInit()
{
	mach_timebase_info(&sTimebaseInfo);
}

uint64_t GetNanoseconds()
{
	assert(sTimebaseInfo.denom != 0);
    
	return (mach_absolute_time() * sTimebaseInfo.numer / sTimebaseInfo.denom);
}
#else
void NanosecondsInit()
{
}
uint64_t GetNanoseconds()
{
    timespec time;
    clock_gettime(CLOCK_REALTIME, &time);
    
    return time.tv_nsec + (uint64_t) time.tv_sec * (1000 * 1000 * 1000);
}
#endif



#ifdef TARGET_OS_IPHONE
#ifndef DISABLE_SOUND
SOUND_TYPE LoadSound(NSString *name)
{
	SystemSoundID soundID = 0;
	if (globalSettings.soundEnabled)
		AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:(name) ofType:@"caf"]], &soundID);
	return soundID;
}
void Play_Sound(SOUND_TYPE soundID)
{
	if (globalSettings.soundEnabled)
		AudioServicesPlaySystemSound(soundID);
}
void UnloadSound(SOUND_TYPE soundID)
{
	if (globalSettings.soundEnabled)
		AudioServicesDisposeSystemSoundID(soundID);
}
#endif

#elif defined (SDL)

SOUND_TYPE LoadSound(NSString *name)
{
#ifndef DISABLE_SOUND
    if (!globalSettings.soundEnabled)
        return NULL;
    
    Mix_Chunk *chunk = Mix_LoadWAV([[[NSBundle mainBundle] pathForResource:name ofType:@"wav"] fileSystemRepresentation]);
    if (!chunk)
        NSLog(@"Error: could not LoadWAV named: %s", [name UTF8String]);
    return chunk;
#endif
}

void Play_Sound(SOUND_TYPE soundID)
{
#ifndef DISABLE_SOUND
    if (!globalSettings.soundEnabled || !soundID)
        return;
    
    int res = Mix_PlayChannel(-1, soundID, 0);
    
    if (res == -1)
        NSLog(@"Warning: could not play chunk %lx", (long)soundID);
#endif
}

void UnloadSound(SOUND_TYPE soundID)
{
#ifndef DISABLE_SOUND
    if (globalSettings.soundEnabled && soundID)
        Mix_FreeChunk(soundID);
#endif
}

#else

SOUND_TYPE LoadSound(NSString *name)
{
#ifndef DISABLE_SOUND
	if (globalSettings.soundEnabled)
	{
#ifdef __COCOTRON__
		return [[NSSound soundNamed:name] retain];
#else
        
		NSString *wavPath = [[NSBundle mainBundle] pathForResource:(name) ofType:@"wav"];
        
		if ( !wavPath)
            fatal("Error: there is no sound named: %s", [name UTF8String]);
        
		NSSound *s = [[NSSound alloc] initWithContentsOfURL:[NSURL fileURLWithPath:wavPath] byReference:NO];
        
		[s setVolume:globalSettings.soundVolume];
        
		return s;
#endif
	}
	else
#endif
		return NULL;
}
void Play_Sound(SOUND_TYPE soundID)
{
#ifndef DISABLE_SOUND
	if (globalSettings.soundEnabled)
		[soundID play];
#endif
}
void UnloadSound(SOUND_TYPE soundID)
{
#ifndef DISABLE_SOUND
	if (globalSettings.soundEnabled && soundID)
    {
        [soundID stop];
        [soundID release];
    }
	soundID = nil;
#endif
}
#endif

NSSize CalculateReducedResolution(const NSSize sr)
{
    NSSize ret;
    
	switch ($defaulti(kFullscreenResolutionFactorKey))
	{
		case 0:
			break;
		case 1:
			ret.width = sr.width * 4 / 5;
			ret.height = sr.height * 4 / 5;
			break;
		case 2:
			ret.width = sr.width * 3 / 4;
			ret.height = sr.height * 3 / 4;
			break;
		case 3:
			ret.width = sr.width * 2 / 3;
			ret.height = sr.height * 2 / 3;
			break;
		case 4:
			ret.width = sr.width * 1 / 2;
			ret.height = sr.height * 1 / 2;
			break;
		case 5:
			ret.width = sr.width * 2 / 5;
			ret.height = sr.height * 2 / 5;
			break;
		case 6:
			ret.width = sr.width * 1 / 3;
			ret.height = sr.height * 1 / 3;
			break;
	}
    
	return sr;
}

vector3f component_mult3(const vector3f& v1, const vector3f& v2)
{
    return vector3f(v1[0]*v2[0], v1[1]*v2[1], v1[2]*v2[2]);
}

vector4f component_mult4(const vector4f& v1, const vector4f& v2)
{
    return vector4f(v1[0]*v2[0], v1[1]*v2[1], v1[2]*v2[2], v1[3]*v2[3]);
}

GLint myGetInteger(GLenum pname)
{
    GLint ret = 0; 
    glGetIntegerv(pname, &ret);
    return ret;
}

const GLubyte *myErrorString(GLenum errorCode)
{
    if (errorCode == GL_NO_ERROR)
        return (GLubyte *) "no error";
    else if (errorCode == GL_INVALID_VALUE)
        return (GLubyte *) "invalid value";
    else if (errorCode == GL_INVALID_ENUM)
        return (GLubyte *) "invalid enum";
    else if (errorCode == GL_INVALID_OPERATION)
        return (GLubyte *) "invalid operation";
    else if (errorCode == GL_OUT_OF_MEMORY)
        return (GLubyte *) "out of memory";
    else
        return (GLubyte *) "unknown error";
}

BOOL HasExtension(NSString *ext)
{
//    if (!globalInfo.modernOpenGL)
//    {
        NSString *extensions = [NSString stringWithUTF8String:(const char *)glGetString(GL_EXTENSIONS)];
        return CONTAINS(extensions, ext);
//    }
//    else
//    {
//        int extCount;
//        glGetIntegerv(GL_NUM_EXTENSIONS, &extCount);
//        for(int i = 0; i < extCount; i++)
//        {
//            NSString *oneExt = [NSString stringWithUTF8String:(const char *)glGetStringi(GL_EXTENSIONS, i)];
//            if (CONTAINS(oneExt, ext)) // TODO: this is technically unsafe since we could match substrings but to fix we need to ensure all callers have full string
//                return YES;
//        }
//        return NO;
//    }   
}

void SavePixelsToTGAFile(uint8_t *screenShotBuffer, CGSize bounds, NSString *file)
{
	// convert
    uint8_t* pixel = screenShotBuffer;
    for(int i=0 ; i < bounds.width * bounds.height ; i++)
    {
        pixel[0] ^= pixel[2];
        pixel[2] ^= pixel[0];
        pixel[0] ^= pixel[2];
        
        pixel += 4;
    }

	// construct header
    uint8_t header[18];
    memset(header, 0, 18);
    header[2] = 2;
    header[12] = ((int)bounds.width & 0x00FF);
    header[13] = ((int)bounds.width & 0xFF00) / 256;
    header[14] = ((int)bounds.height & 0x00FF) ;
    header[15] = ((int)bounds.height & 0xFF00) / 256;
    header[16] = 32 ;

	// write out
    FILE* screenshotFile = fopen([file UTF8String], "wb");
    fwrite(&header, 18, sizeof(uint8_t), screenshotFile);
    fwrite(screenShotBuffer, bounds.width * bounds.height, 4 * sizeof(uint8_t), screenshotFile);
    fclose(screenshotFile);
}