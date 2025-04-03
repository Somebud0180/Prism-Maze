// From https://godotshaders.com/shader/pbr-glass/

shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, blend_mix, shadows_disabled, vertex_lighting;

group_uniforms albedo;
uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform sampler2D albedo_texture : source_color, hint_default_white;

group_uniforms roughness;
uniform float roughness : hint_range(0.0, 1.0) = 0.15;
uniform sampler2D roughness_texture : hint_roughness_r;

group_uniforms normal;
uniform float normal_strength : hint_range(-16.0, 16.0) = 1.0;
uniform sampler2D normal_map : hint_normal;

group_uniforms misc;
uniform vec4 edge_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

global uniform vec3 character_position;
uniform float fade_distance;

varying vec3 world_vertex;

void vertex() {
	world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float SchlickFresnel(float u) {
	float m = 1.0 - u;
	float m2 = m * m;
	return m2 * m2 * m;
}

void fragment() {
	// calculate fresnel values
	float VdotN = dot(VIEW, NORMAL);
	float fresnel = clamp(SchlickFresnel(VdotN), 0.0, 1.0);

	// sample and mix textures
	vec4 _albedo = texture(albedo_texture, UV) * albedo;
	float _roughness = texture(roughness_texture, UV).r * roughness;

	// Calculate the distance between the fragment and the character
	float chardistance = length(character_position - world_vertex);

	// apply glass look
	float a = mix(0.001, 1.0, _albedo.a);
	float alpha = 1.0 - smoothstep(0.0, fade_distance, chardistance);
	ALPHA = mix(fresnel * edge_color.a, 1.0, a) * alpha;

	// Calculate the alpha value based on the distanceg
	if (alpha <= 0.0) {
		discard;
	}

	ALBEDO = mix(edge_color.rgb * edge_color.a, _albedo.rgb, a);

	ROUGHNESS = _roughness;
	NORMAL_MAP = texture(normal_map, UV).xyz;
	NORMAL_MAP_DEPTH = normal_strength;

	// function to compensate specular for alpha blend
	// 0.5 * ALPHA^-0.5
	SPECULAR = 0.5 * inversesqrt(ALPHA);
}