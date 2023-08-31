//arc!vec2:sinCosAperture:[0.7071067812, -0.7071067812]|float:radius:1
float sd/*NAME*/( in vec2 p, in vec2 sc, in float ra ) {
	// sc is the sin/cos of the arc's aperture
	p.x = abs(p.x);
	return ((sc.y*p.x>sc.x*p.y) ? length(p-sc*ra) : abs(length(p)-ra));
}
//SEPARATOR
vec2 rotateSC(vec2 p, vec2 sc) {
	mat2 m = mat2(sc.y, -sc.x, sc.x, sc.y);
	return m * p;
}
vec4 vf/*NAME*/( in vec2 v, in vec2 of, in vec2 sc, in float ra ) {
	vec2 up = vec2(0.0, -1.0);
	float dp = dot(up, v) * 0.5 + 0.5;
	vec2 nv = v;
	vec2 nof = of;
	return vec4(nv * ra, nof);
}
