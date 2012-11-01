


#ifdef COLOR
uniform vec4 color;
#else
uniform float 	intensity;
uniform sampler2D 	pointspriteTexture;
#endif


void main()
{
#ifdef COLOR
    fragColor = color;
    float x = length(gl_PointCoord - vec2(0.5, 0.5));
    fragColor.a = 4.5 + 1.0 - x * 10.0; // nice antialising throgh smoothly going from 1.0 opacity at r = 0.9 to 0.0 opacity at r = 1.1
#else
	fragColor = texture2D(pointspriteTexture, gl_PointCoord);
	fragColor.w *= intensity;
#endif
}