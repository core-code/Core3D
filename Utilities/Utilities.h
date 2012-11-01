#import "Core3D.h"

// ad-hoc rect drawing
void DrawQuadWithCoordinates(const GLshort x1, const GLshort y1, const GLshort x2, const GLshort y2, const GLshort x3, const GLshort y3, const GLshort x4, const GLshort y4);
void DrawQuadWithCoordinatesRotation(const GLshort x1, const GLshort y1, const GLshort x2, const GLshort y2, const GLshort x3, const GLshort y3, const GLshort x4, const GLshort y4, const GLfloat rotation);
void DrawARFullScreenQuad(const short textureWidth, const short textureHeight);
void DrawCenteredScreenQuad(const short textureWidth, const short textureHeight);

// collision detection
char AABoxInFrustum(const float frustum[6][4], const float x, const float y, const float z, const float ex, float ey, const float ez);

// timing
void NanosecondsInit();
uint64_t GetNanoseconds();

// sound
SOUND_TYPE LoadSound(NSString *name);
void Play_Sound(SOUND_TYPE soundID);
void UnloadSound(SOUND_TYPE soundID);

// file-format support
void * UncompressedBufferFromSNZFile(FILE *f);
void SavePixelsToTGAFile(uint8_t *screenShotBuffer, CGSize bounds, NSString *file);

// opengl support
BOOL HasExtension(NSString *ext);
const GLubyte *myErrorString(GLenum errorCode);
GLint myGetInteger(GLenum pname);

// misc
NSSize CalculateReducedResolution(NSSize sr);