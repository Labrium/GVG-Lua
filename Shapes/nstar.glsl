//ngon!float:radius:1|float:inset:0.5|int:points:7
float sd/*NAME*/(vec2 p, float radius, float inset, float n){
	p.y = -p.y;
	float teta = 6.28318530717958647692528 / n;
	mat2x2 rot1 = mat2x2(cos(teta), sin(teta), -sin(teta), cos(teta));

	vec2 p1 = vec2(0.0, radius);
	vec2 p2 = vec2(sin(teta*0.5), cos(teta*0.5))*radius*inset;

	float tetaP = (6.28318530717958647692528 * 0.5) + atan(-p.x, -p.y);
	tetaP = mod(tetaP + (6.28318530717958647692528 * 0.5) / n, 6.28318530717958647692528);
	
	for(float i = teta; i < tetaP; i+= teta)
		 p = rot1 *p;

	p.x = abs(p.x);

	// sdf segment
	vec2 ba = p2-p1;
	vec2 pa = p - p1;
	float h =clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	float d = length(pa-h*ba);
	d *= sign(dot(p - p1, -vec2(ba.y, -ba.x)));
	return d;
}
//SEPARATOR
vec4 vf/*NAME*/( in vec2 v, in vec2 of, float radius, float inset, float n) {
	v.y = -v.y;
	of.y = -of.y;
	return vec4(v * radius, of);
}