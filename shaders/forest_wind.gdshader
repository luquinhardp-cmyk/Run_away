shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform vec4 tint : source_color = vec4(0.025,0.045,0.032,1.0);
uniform float wind_strength = 0.05;
void vertex() {
	vec3 world = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	VERTEX.x += sin(TIME*0.45+world.x*0.08+world.z*0.045)*wind_strength*smoothstep(1.5,9.0,VERTEX.y);
}
void fragment() { ALBEDO = tint.rgb; ROUGHNESS = 0.97; }
