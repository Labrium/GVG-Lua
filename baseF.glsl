// GVG 0.4 Copyright (c) 2023 Labrium.

//#define PI 6.28318530717958647692528 / 2
extern float scl;
extern float stroke;
extern float offset;
extern bool line;

/*UNIFORMS*/

float round(in float a) {return floor(a + 0.5);}

float dot2(in vec2 v) {return dot(v,v);}

float cro(in vec2 a, in vec2 b) {return a.x*b.y - a.y*b.x;}

/*FUNCTION*/

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
	tc = vec2(tc.x, -tc.y);
	float d = ((sd/*NAME*/(tc / scl/*PARAMETERS*/) - offset) * scl);
	if (line) { d = abs(d); }
	d -= (stroke * 0.5) - 0.5;
	//if (d > 1.0) { return vec4(mod(tc.xy, 100.0) / 100.0, 0.5, 0.5); }
	vec3 col = gammaToLinear(color).rgb;
	//col = mix(col, col * 0.25, clamp(d + (4.0 * scl), 0.0, 1.0));
	d = 1.0 - clamp(d, 0.0, 1.0);
	//col.rgb = mix(col.rgb * (((atan(tc.x, tc.y) + PI) / 2) / PI));
	return vec4(linearToGamma(col.rgb), d * color.a);
}
