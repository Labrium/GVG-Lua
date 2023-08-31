//ngon!float:radius:1
float sd/*NAME*/( in vec2 p, in float r ) {
	const vec3 k = vec3(0.809016994,0.587785252,0.726542528);
	p.x = abs(p.x);
	p -= 2.0*min(dot(vec2(-k.x,k.y),p),0.0)*vec2(-k.x,k.y);
	p -= 2.0*min(dot(vec2( k.x,k.y),p),0.0)*vec2( k.x,k.y);
	p -= vec2(clamp(p.x,-r*k.z,r*k.z),r);    
	return length(p)*sign(p.y);
}
//SEPARATOR
vec4 vf/*NAME*/( in vec2 v, in vec2 of, in float r ) {
	return vec4(v * r, of);
}