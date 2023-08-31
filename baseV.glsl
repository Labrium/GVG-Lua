// GVG 0.4 Copyright (c) 2023 Labrium.

attribute vec4 VertexOffset;

extern vec2 pos;
extern float rot;
extern float scl;
extern float stroke;
extern float offset;

/*UNIFORMS*/

vec2 rotate(vec2 v, float a) {
	float s = sin(a); float c = cos(a);
	mat2 m = mat2(c, -s, s, c);
	return m * v;
}

vec2 rotateByVec(vec2 a, vec2 b) {
	return vec2(dot(b, a), dot(vec2(b.y, -b.x), a));
}

/*FUNCTION*/

vec4 position(mat4 tp, vec4 vp) {
	vec4 vf = vf/*NAME*/(vp.xy, VertexOffset.xy/*PARAMETERS*/);
	vec2 nvp = vf.xy * scl + vf.zw * (1 + (stroke * scl * 0.5 + offset * scl));
	VaryingTexCoord = vec4(nvp, 0.0, 1.0);
	nvp = rotate(nvp, rot);
	return vec4((nvp + pos) / love_ScreenSize.xy, 0.0, 0.5);
}
