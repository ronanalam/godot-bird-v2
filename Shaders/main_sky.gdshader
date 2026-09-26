shader_type sky;

void sky() {
	// SPHERICAL COORDINATES
	//float rho = sqrt(dot(EYEDIR,EYEDIR));
	float theta = ( atan(EYEDIR.z,-EYEDIR.x) + PI )/2.;
	float phi = asin(EYEDIR.y);
	
	//vec2 sun_dir = vec2(PI/4.,PI/3.); // (longitude, elevation)
	//vec2 sun_dir_thetaphicoords = vec2( theta - sun_dir.x, phi + sun_dir.y );
	
	float sun_angle = 4.0; //deg
	vec3 sun_dir = vec3( 0.707, 0.707, 0. );
	vec3 sun_color = vec3( sign(dot(sun_dir,EYEDIR)-cos(sun_angle*PI/180.)) );
	sun_color = clamp( sun_color, 0.0, 10.0 );
	
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
	COLOR = sun_color + vec3( sin(8.*theta)*sign(-phi), 0.2, sign(phi) );
}