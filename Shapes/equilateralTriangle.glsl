//equilateralTriangle!float:radius:1
float sd/*NAME*/( in vec2 p, in float r) {
	const float k = sqrt(3.0);
	p.x = abs(p.x) - r;
	p.y = -p.y + r/k;
	if( p.x+k*p.y>0.0 ) p=vec2(p.x-k*p.y,-k*p.x-p.y)/2.0;
	p.x -= clamp( p.x, -2.0*r, 0.0 );
	return -length(p)*sign(p.y);
}
//SEPARATOR
vec4 vf/*NAME*/(vec2 v, vec2 of, float r) {
	return vec4(v * r, of);
}