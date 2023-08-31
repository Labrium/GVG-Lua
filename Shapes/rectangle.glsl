//square!vec2:size:[1, 1]
float sd/*NAME*/( in vec2 p, in vec2 b ) {
	vec2 d = abs(p)-b;
	return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}
//SEPARATOR
vec4 vf/*NAME*/(in vec2 v, in vec2 of, in vec2 b ) {
	return vec4(v * b, of);
}