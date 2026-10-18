shader_type sky;



uniform vec3 sun_dir;
uniform float sun_disk_angle;
const vec3 sky_color = vec3(0.10, 0.7, 1.0);



void sky() {
	vec3 rgb = vec3(0.0);
	
	// SPHERICAL COORDINATES
	//float rho = sqrt(dot(EYEDIR,EYEDIR));
	float theta = ( atan(EYEDIR.z,-EYEDIR.x) + PI )/2.;
	float phi = asin(EYEDIR.y);
	
	rgb.r = 0.2 * exp(-pow(EYEDIR.y/0.25,2.));
	rgb.g = 0.4 * exp(-pow(EYEDIR.y/0.75,2.));
	rgb.b = 1. - 0.2*exp(-pow(EYEDIR.y/0.95,2.));
	
	if ( acos(dot(EYEDIR,sun_dir)) < sun_disk_angle*(PI/180.) ) {
		rgb = vec3(20.0,20.0,1.0);
	}
	
	COLOR = rgb;
}