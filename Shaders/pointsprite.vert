


uniform mat4 modelViewProjectionMatrix;

attribute vec4 vertex;



uniform float size;
uniform float pointSize;
uniform float minSize;
uniform float maxSize;

void main(void)
{
	gl_Position = modelViewProjectionMatrix * vec4(vertex[0] * size, vertex[1] * size, vertex[2] * size, 1.0);

#ifdef SCALE_PARTICLES
    gl_PointSize = pointSize / (gl_Position[2]);
    
    #ifdef MAX_SIZE
        if (gl_PointSize > maxSize) gl_PointSize = maxSize;
    #endif
    
    #ifdef MIN_SIZE
        if (gl_PointSize < minSize) gl_PointSize = minSize;
    #endif
#else
	gl_PointSize = pointSize;
#endif
}
