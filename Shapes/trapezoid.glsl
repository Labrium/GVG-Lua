//trapezoid!float:base1:1|float:base2:0.5|float:height:0.5
float sd/*NAME*/(vec2 p, float r1, float r2, float he ) {
	vec2 k1 = vec2(r2, he);
	vec2 k2 = vec2(r2 - r1, 2.0 * he);
	p.x = abs(p.x);
	vec2 ca = vec2(p.x - min(p.x, (p.y < 0.0) ? r1 : r2), abs(p.y) - he);
	vec2 cb = p - k1 + k2 * clamp(dot(k1 - p, k2) / dot2(k2), 0.0, 1.0);
	float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
	return s * sqrt(min(dot2(ca), dot2(cb)));
}
//SEPARATOR
vec4 vf/*NAME*/(vec2 v, vec2 of, float r1, float r2, float he) {
	float sb = min(r1, r2);
	float lb = max(r1, r2);
	float fy = r1 < r2 ? 1.0 : -1.0;
	vec4 xs = vec4(sign(v.x), fy, sign(v.x), fy);
	if (of.y < 0.0) {
		vec2 lastV = vec2(sb, he);
		vec2 V = vec2(lb, -he);
		vec2 nextV = vec2(0.0, -he);
	
		vec2 lastDir = normalize(V - lastV);
		vec2 nextDir = normalize(V - nextV);
	
		vec2 miterDir = normalize(lastDir + nextDir);
	
		vec2 bevelPoint;
		if (of.x > 0) {
			bevelPoint = vec2(-lastDir.y, lastDir.x);
		} else {
			bevelPoint = vec2(nextDir.y, -nextDir.x);
		}
	
		bevelPoint = normalize(bevelPoint + miterDir);
	
		return vec4(V, bevelPoint / dot(bevelPoint, miterDir)) * xs;
	} else {
		vec2 lastV = vec2(0.0, he);
		vec2 V = vec2(sb, he);
		vec2 nextV = vec2(lb, -he);
	
		vec2 lastDir = normalize(V - lastV);
		vec2 nextDir = normalize(V - nextV);
	
		vec2 miterDir = normalize(lastDir + nextDir);
		
		vec2 segmentNormal = vec2(-lastDir.y, lastDir.x);
	
		return vec4(V, miterDir / dot(miterDir, segmentNormal)) * xs;
	}
}