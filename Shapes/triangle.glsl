//triangle!vec2:point1:[-1, -0.75]|vec2:point2:[1, 1]|vec2:point3:[1, -0.25]
float sd/*NAME*/( in vec2 p, in vec2 p0o, in vec2 p1o, in vec2 p2o ) {
	vec2 p0 = vec2(p0o.x, -p0o.y);
	vec2 p1 = vec2(p1o.x, -p1o.y);
	vec2 p2 = vec2(p2o.x, -p2o.y);
	vec2 e0 = p1 - p0, e1 = p2 - p1, e2 = p0 - p2;
	vec2 v0 = p  - p0, v1 = p  - p1, v2 = p  - p2;
	vec2 pq0 = v0 - e0 * clamp(dot(v0, e0) / dot(e0, e0), 0.0, 1.0);
	vec2 pq1 = v1 - e1 * clamp(dot(v1, e1) / dot(e1, e1), 0.0, 1.0);
	vec2 pq2 = v2 - e2 * clamp(dot(v2, e2) / dot(e2, e2), 0.0, 1.0);
	float s = sign(e0.x * e2.y - e0.y * e2.x);
	vec2 d = min(min(vec2(dot(pq0, pq0), s * (v0.x * e0.y-v0.y * e0.x)),
					vec2(dot(pq1, pq1), s * (v1.x * e1.y-v1.y * e1.x))),
					vec2(dot(pq2, pq2), s * (v2.x * e2.y-v2.y * e2.x)));
	return -sqrt(d.x) * sign(d.y);
}
//SEPARATOR
vec4 vf/*NAME*/( in vec2 v, in vec2 of, in vec2 p0, in vec2 p1, in vec2 p2 ) {
	vec2 lastV;
	vec2 V;
	vec2 nextV;

	vec4 p02 = vec4(p0, p2); // makes it easier to flip the angle

	if (cross(vec3(p1 - p0, 0.0), vec3(p2 - p0, 0.0)).z > 0.0) { // correct for counter-clockwise winding
		p02 = p02.zwxy;
	}

	if (abs(of.x) == 1.0) { // of doesn't contain actual vertex offset data in this case
		lastV = p02.zw;
		V = p02.xy;
		nextV = p1;
	} else if (abs(of.x) == 2.0) {
		lastV = p02.xy;
		V = p1;
		nextV = p02.zw;
	} else if (abs(of.x) == 3.0) {
		lastV = p1;
		V = p02.zw;
		nextV = p02.xy;
	}

	vec2 lastDir = normalize(V - lastV);
	vec2 nextDir = normalize(V - nextV);

	vec2 miterDir = normalize(lastDir + nextDir);

	vec2 bevelPoint;
	if (of.x < 0) {
		bevelPoint = vec2(-lastDir.y, lastDir.x);
	} else {
		bevelPoint = vec2(nextDir.y, -nextDir.x);
	}

	bevelPoint = normalize(bevelPoint + miterDir);

	return vec4(V, bevelPoint / dot(bevelPoint, miterDir));
}