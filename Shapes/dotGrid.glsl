//square!vec2:spacing:[10, 10]
float sd/*NAME*/( vec2 p, vec2 s ) {
	return distance(p, floor((p + (s * 0.5)) / s) * s);
}
//SEPARATOR
vec4 vf/*NAME*/( vec2 v, vec2 of, vec2 s ) {
	return vec4(rotate((v * (love_ScreenSize.xy * 0.5)) - pos, -rot) / scl, vec2(0.0));
}