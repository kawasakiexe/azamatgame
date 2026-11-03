shader_type spatial;
render_mode vertex_lighting, specular_disabled, shadows_disabled;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_enable;
uniform bool use_texture = false;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec3 emission_color : source_color = vec3(0.0);
uniform float emission_energy : hint_range(0.0, 8.0) = 0.0;
uniform float snap_resolution : hint_range(60.0, 480.0) = 180.0;
uniform float jitter_amount : hint_range(0.0, 1.0) = 0.65;

void vertex() {
	UV = UV * uv_scale;
	// Classic PS1 Vertex Snapping in Clip Space
	vec4 clip_pos = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec2 snap_grid = vec2(snap_resolution, snap_resolution * 0.75);
	vec2 snapped = floor((clip_pos.xy / clip_pos.w) * snap_grid + 0.5) / snap_grid;
	clip_pos.xy = mix(clip_pos.xy, snapped * clip_pos.w, jitter_amount);
	POSITION = clip_pos;
}

void fragment() {
	vec3 base = albedo_color.rgb;
	if (use_texture) {
		base *= texture(albedo_tex, UV).rgb;
	}
	ALBEDO = base;
	EMISSION = emission_color * emission_energy;
	ROUGHNESS = 1.0;
}
