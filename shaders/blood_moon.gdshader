shader_type sky;
render_mode use_debanding;
uniform sampler2D moon_texture : source_color, filter_linear_mipmap;
uniform vec3 moon_direction = vec3(0.15,0.7,0.7);
uniform float moon_radius = 0.105;
uniform float star_strength = 0.24;
float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void sky() {
	vec3 ray = normalize(EYEDIR);
	float altitude = max(ray.y,0.0);
	vec3 color = mix(vec3(0.070,0.077,0.100),vec3(0.040,0.055,0.085),smoothstep(0.0,0.7,altitude));
	vec2 spherical = vec2(atan(ray.z,ray.x)/6.2831853+0.5,asin(clamp(ray.y,-1.0,1.0))/3.1415927+0.5);
	vec2 grid = spherical*vec2(320.0,160.0);
	vec2 cell = floor(grid);
	float seed = hash21(cell);
	vec2 offset = vec2(hash21(cell+17.0),hash21(cell+53.0));
	float point = length(fract(grid)-mix(vec2(0.18),vec2(0.82),offset));
	float size = mix(0.10,0.17,pow(seed,45.0));
	float stars = (1.0-smoothstep(size*0.2,size,point))*step(0.991,seed)*smoothstep(0.01,0.14,ray.y);
	color += vec3(0.66,0.72,0.78)*stars*mix(0.9,3.0,hash21(cell+9.0))*star_strength;
	vec3 moon = normalize(moon_direction);
	vec3 right = normalize(cross(vec3(0.0,1.0,0.0),moon));
	vec3 up = cross(moon,right);
	vec2 disk = vec2(dot(ray,right),dot(ray,up))/moon_radius;
	float radius = length(disk);
	float front = step(0.0,dot(ray,moon));
	float terrain = texture(moon_texture,disk*0.5+0.5).r;
	float edge = 1.0+(terrain-0.5)*0.012;
	float mask = (1.0-smoothstep(edge-0.008,edge+0.002,radius))*front;
	float light = 0.30+0.70*sqrt(max(0.0,1.0-radius*radius));
	vec3 red = mix(vec3(0.12,0.012,0.007),vec3(0.62,0.075,0.025),terrain)*light;
	color += vec3(0.085,0.004,0.001)*exp(-max(0.0,radius-1.0)*9.0)*front*(1.0-mask);
	COLOR = mix(color,red,mask);
}
