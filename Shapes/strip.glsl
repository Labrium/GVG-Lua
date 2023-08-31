//square!vec2:point1:[-0.75, -0.75]|vec2:point2:[0.75, 0.75]|float:width:0.5
float sd/*NAME*/( in vec2 p, in vec2 ao, in vec2 bo, float th ) {
	vec2 a = vec2(ao.x, -ao.y);
	vec2 b = vec2(bo.x, -bo.y);
	float l = length(b-a);
	vec2  d = (b-a)/l;
	vec2  q = (p-(a+b)*0.5);
	q = mat2(d.x,-d.y,d.y,d.x)*q;
	q = abs(q)-vec2(l,th)*0.5;
	return length(max(q,0.0)) + min(max(q.x,q.y),0.0);    
}
//SEPARATOR
vec4 vf/*NAME*/(in vec2 v, in vec2 of, in vec2 a, in vec2 b, float th) {
	vec2 dir = normalize(b - a);
	if (length(dir) == 0.0) {
		dir = vec2(1.0, 0.0);
	}
	vec2 rof = rotateByVec(of, dir);
	if (v.x < 0.0) {
		return vec4(a + rotateByVec(vec2(0.0, th * 0.5 * sign(v.y)), dir), rof);
	}
	return vec4(b + rotateByVec(vec2(0.0, th * 0.5 * sign(v.y)), dir), rof);
}