//square!vec2:spacing:[10, 10]
float sd/*NAME*/( vec2 pa, vec2 s ) {
	vec2 p = pa / s;
	return min(distance(vec2(floor(p.x + 0.5), p.y), p) * s.x, distance(vec2(p.x, floor(p.y + 0.5)), p) * s.y);
}
//SEPARATOR
vec4 vf/*NAME*/( vec2 v, vec2 of, vec2 s ) {
	return vec4(rotate((v * (love_ScreenSize.xy * 0.5)) - pos, -rot) / scl, vec2(0.0));
}