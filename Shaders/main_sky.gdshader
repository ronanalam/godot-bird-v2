shader_type sky;

void sky() {
	// SPHERICAL COORDINATES
	//float rho = sqrt(dot(EYEDIR,EYEDIR));
	float theta = ( atan(EYEDIR.z,-EYEDIR.x) + PI )/2.;
	float phi = asin(EYEDIR.y);
	
	// _s denotes "sky"
	//float red_s = dot(EYEDIR, vec3(0,0.21,0));
	//float grn_s = dot(EYEDIR, vec3(0,0.8,0));
	//float blu_s = dot(EYEDIR, vec3(0,1,0));
	//
	//// _g denotes "ground"
	//float red_g = dot(EYEDIR, vec3(0,-0.21,0));
	//float grn_g = dot(EYEDIR, vec3(0,-0.8,0));
	//float blu_g = dot(EYEDIR, vec3(0,-1,0));
	
	//COLOR = 1.*vec3( red_s, grn_s, blu_s ) + 0.0*vec3( red_g, grn_g, blu_g );
	COLOR = vec3( sin(8.*theta)*sign(-phi), 0.2, sign(phi) );
}