

uniform mat4 modelViewProjectionMatrix;

attribute vec4 vertex;
attribute vec2 texcoord0;
#ifdef ATTRIBUTECOLOR
attribute vec3 normal;
varying_vert vec3 color;
#endif
varying_vert vec2 texcoord;


void main( void )
{
    gl_Position = modelViewProjectionMatrix * vertex;
    texcoord    = texcoord0.xy;
#ifdef ATTRIBUTECOLOR
    color = normal;
#endif
}