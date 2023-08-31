//square!vec2:point1:[-0.75, -0.75]|vec2:point2:[0.75, 0.75]
float sd/*NAME*/( in vec2 p, in vec2 ao, in vec2 b ) {
	vec2 a = vec2(ao.x, -ao.y);
	vec2 pa = p-a, ba = vec2(b.x, -b.y)-a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h );
}
//SEPARATOR
vec4 vf/*NAME*/(in vec2 v, in vec2 of, in vec2 a, in vec2 b) {
	vec2 dir = normalize(b - a);
	if (length(dir) == 0.0) {
		dir = vec2(1.0, 0.0);
	}
	vec2 rof = rotateByVec(of, dir);
	if (v.x < 0.0) {
		return vec4(a, rof);
	}
	return vec4(b, rof);
}