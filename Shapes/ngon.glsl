//ngon!float:radius:1|int:points:7
float sd/*NAME*/( in vec2 p, in float r, in int points ) {
	// these 2 lines can be precomputed
	float an = 6.2831853/float(points);
	float he = r*tan(0.5*an);
	
	// rotate to first sector
	p = p.yx;
	float bn = an*floor((atan(p.y,p.x)+0.5*an)/an);
	vec2  cs = vec2(cos(bn),sin(bn));
	p = mat2(cs.x,-cs.y,cs.y,cs.x)*p;

	// side of polygon
	return length(p-vec2(r,clamp(p.y,-he,he)))*sign(p.x-r);
}
//SEPARATOR
vec4 vf/*NAME*/( in vec2 v, in vec2 of, in float r, in int points ) {
	return vec4(v * r, of);
}