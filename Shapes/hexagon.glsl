//ngon!float:radius:1
float sd/*NAME*/( in vec2 p, in float r ) {
	const vec3 k = vec3(-0.866025404,0.5,0.577350269);
	p = abs(p);
	p -= 2.0*min(dot(k.xy,p),0.0)*k.xy;
	p -= vec2(clamp(p.x, -k.z*r, k.z*r), r);
	return length(p)*sign(p.y);
}
//SEPARATOR
vec4 vf/*NAME*/( in vec2 v, in vec2 of, in float r ) {
	return vec4(v * r, of);
}