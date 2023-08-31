//ngon!float:radius:1
float sd/*NAME*/(vec2 p, float r) {
	return length(p) - r;
}
//SEPARATOR
vec4 vf/*NAME*/(vec2 v, vec2 of, float r) {
	return vec4(v * r, of);
}