uniform mat4 modelViewProjectionMatrix;
uniform mat4 modelViewMatrix;
uniform mat3 normalMatrix;

attribute vec4 vertex;
#ifdef TEXTURE
attribute vec2 texcoord0;
#endif
attribute vec3 normal;

#ifdef TEXTURE
varying_vert vec2 texcoord;
#endif
varying_vert vec3 position;
varying_vert vec3 normalVector;

void main( void )
{
	normalVector = normalize(normalMatrix * normal);
	position	= vec3(modelViewMatrix * vertex);

#ifdef TEXTURE
	texcoord    = texcoord0.xy;
#endif
    
	gl_Position = modelViewProjectionMatrix * vertex;
}

