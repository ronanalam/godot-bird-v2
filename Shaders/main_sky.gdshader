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
	
	rgb.b = dot(EYEDIR,sun_dir);
	
	if ( acos(dot(EYEDIR,sun_dir)) < sun_disk_angle*(PI/180.) ) {
		rgb = vec3(5.0);
	}
	
	COLOR = rgb;
}