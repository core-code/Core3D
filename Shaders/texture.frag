uniform sampler2D texUnit;


varying_frag  vec2 texcoord;
#ifdef ATTRIBUTECOLOR
varying_frag  vec3 color;
#else
uniform vec4 color;
#endif

#ifdef ADDITIONALBLEND
uniform float additionalBlendFactor;
#endif

void main (void)
{
	fragColor =  texture2D(texUnit, texcoord);
#ifdef ATTRIBUTECOLOR
    fragColor += vec4(color.r, color.g, color.b, 0.0);
#else
    fragColor *= color;
#endif
    
#ifdef ADDITIONALBLEND
    fragColor.a *= additionalBlendFactor;
#endif
}
