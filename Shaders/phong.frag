uniform vec3 light1position;
uniform vec4 light1product_ambient;
uniform vec4 light1product_diffuse;
uniform vec4 light1product_specular;
uniform vec4 lightmodelproduct_scenecolor;
uniform float material_shininess;

#ifdef TEXTURE
uniform sampler2D texUnit;
#endif

varying_frag vec3 normalVector; // eye space
varying_frag vec3 position;     // eye space

#ifdef TEXTURE
varying_frag vec2 texcoord;
#endif

void main (void)
{
	vec3 eyeDir 	= normalize(-position); // camera is at (0,0,0) in ModelView space
	vec3 lightDir	= normalize(light1position - position);
	vec4 IAmbient	= light1product_ambient;
	vec4 IDiffuse	= light1product_diffuse * max(dot(normalVector, lightDir), 0.0);
	vec3 Reflected	= normalize(reflect( -lightDir, normalVector));
#ifdef TEXTURE
	vec4 tex        = texture2D(texUnit, texcoord);
#endif
	vec4 ourcolor  	= vec4(lightmodelproduct_scenecolor + IAmbient + IDiffuse);
    
	ourcolor     	+= (light1product_specular * pow(max(dot(Reflected, eyeDir), 0.0), material_shininess));
    ourcolor.a      = 1.0;
#ifdef TEXTURE    
    ourcolor        *= tex;
#endif
    
	fragColor	= ourcolor;
}

