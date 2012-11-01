#ifndef STATEUTILITIES_H
#define STATEUTILITIES_H 1

#ifdef __cplusplus
extern "C" {
#endif // ifdef __cplusplus
    
    
typedef enum {
    kNeedEnabled = 0,
    kNeedDisabled,
} requirementEnum;

void myClientStateVTN(const requirementEnum vertexneed, const requirementEnum textureneed, const requirementEnum normalneed);
    
void myBlendFunc(const GLenum s, const GLenum d);
void myLineWidth(const GLfloat width);
void myBlendColor(const GLfloat red, const GLfloat green, const GLfloat blue, const GLfloat alpha);
void myPolygonOffset(const GLfloat factor, const GLfloat units);
void myEnableVertexAttribArray(const GLuint index);
void myDisableVertexAttribArray(const GLuint index);
void myViewport(const GLint x, const GLint y, const GLsizei width, const GLsizei height);
void myEnableBlendParticleCullDepthtestDepthwrite(const bool blend, const bool particle, const bool cull, const bool depthTest, const bool depthWrite);

//void myNormalPointer(const GLenum type, const GLsizei stride, const GLvoid *pointer);
//void myVertexPointer(const GLint size, const GLenum type, const GLsizei stride, const GLvoid *pointer);
//void myTexCoordPointer(const GLint size, const GLenum type, const GLsizei stride, const GLvoid *pointer);

void ResetState();
void DeleteState();

GLfloat getLineWidth();

#ifdef __cplusplus
}
#endif // ifdef __cplusplus

#endif 