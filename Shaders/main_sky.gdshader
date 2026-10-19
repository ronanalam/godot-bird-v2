shader_type sky;



uniform vec3 sun_dir;
uniform float sun_disk_angle;
const vec3 sky_color = vec3(0.10, 0.7, 1.0);



void sky() {
	vec3 rgb = vec3(0.0);
	// R: 645 nm
	// G: 510
	// B: 440
	
	// SPHERICAL COORDINATES
	//float rho = sqrt(dot(EYEDIR,EYEDIR));
	float theta = ( atan(EYEDIR.z,-EYEDIR.x) + PI )/2.;
	float phi = asin(EYEDIR.y);
	float Theta = acos( dot(vec3(0.,1.,0.),sun_dir) );
	
	
	rgb.r = 0.2 * exp(-pow(EYEDIR.y/0.25,2.));
	rgb.g = 0.4 * exp(-pow(EYEDIR.y/0.75,2.));
	rgb.b = 1. - 0.2*exp(-pow(EYEDIR.y/0.95,2.));
	
	if ( acos(dot(EYEDIR,sun_dir)) < sun_disk_angle*(PI/180.) ) {
		rgb = 10. * vec3( (cos(2.*Theta)+3.)/4., (cos(2.*Theta)+1.1)/2.1, (cos(2.*Theta)+1.)/2. );
		//rgb = 10. * vec3(0.5,0.05,0.0);
	}
	
	COLOR = rgb;
}