shader_type canvas_item;

// Screen texture for full-screen post-processing (3D world + 2D hands)
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// White Knuckle / PS1 Retro Post-Processing Parameters
uniform vec2 target_resolution = vec2(480.0, 270.0);
uniform float color_levels : hint_range(4.0, 64.0) = 18.0;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.38;
uniform float contrast : hint_range(0.5, 2.0) = 1.12;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.42;
uniform float scanline_opacity : hint_range(0.0, 0.5) = 0.08;
uniform float distortion_glitch : hint_range(0.0, 1.0) = 0.0;
uniform float heat_tint : hint_range(0.0, 1.0) = 0.0;

// 4x4 Bayer matrix normalized to [-0.5, 0.5]
float bayer4x4(ivec2 pos) {
	int x = pos.x & 3;
	int y = pos.y & 3;
	int idx = x + y * 4;
	float m[16] = float[16](
		 0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
		12.0 / 16.0,  4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
		 3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
		15.0 / 16.0,  7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0
	);
	return m[idx] - 0.5;
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	// 1. Low-resolution pixel grid snapping (PS1 / White Knuckle crisp pixels)
	ivec2 low_coord = ivec2(floor(SCREEN_UV * target_resolution));
	vec2 uv = (vec2(low_coord) + 0.5) / target_resolution;

	// 2. Distortion Monster glitch warp
	if (distortion_glitch > 0.001) {
		float slice = floor(uv.y * 45.0 + TIME * 18.0);
		float n = hash12(vec2(slice, floor(TIME * 24.0))) - 0.5;
		uv.x += n * 0.06 * distortion_glitch;
	}

	vec3 col = texture(screen_texture, clamp(uv, vec2(0.0), vec2(1.0))).rgb;

	// Chromatic aberration when distortion monster is stared at
	if (distortion_glitch > 0.01) {
		float shift = 0.008 * distortion_glitch;
		col.r = texture(screen_texture, clamp(uv + vec2(shift, 0.0), vec2(0.0), vec2(1.0))).r;
		col.b = texture(screen_texture, clamp(uv - vec2(shift, 0.0), vec2(0.0), vec2(1.0))).b;
	}

	// 3. Industrial dark contrast curve (White Knuckle deep shadows)
	col = clamp((col - 0.5) * contrast + 0.5, 0.0, 1.0);

	// 4. Ordered 4x4 Bayer Matrix Dithering before color quantization
	float dither = bayer4x4(low_coord);
	col += (dither * dither_strength) / color_levels;

	// 5. PSX Color Quantization (15-bit / indexed palette feel)
	col = floor(clamp(col, 0.0, 1.0) * color_levels + 0.5) / color_levels;

	// 6. Subtle CRT scanline & industrial vignette
	float scan = sin(float(low_coord.y) * 3.14159) * scanline_opacity;
	col -= scan;

	vec2 vig_uv = SCREEN_UV * (1.0 - SCREEN_UV.yx);
	float vig = vig_uv.x * vig_uv.y * 15.0;
	vig = pow(clamp(vig, 0.0, 1.0), vignette_intensity);
	col *= mix(0.35, 1.0, vig);

	// 7. Overheat / Pukan danger pulse
	if (heat_tint > 0.01) {
		col = mix(col, vec3(col.r * 1.35 + 0.15, col.g * 0.55, col.b * 0.45), heat_tint * 0.55);
	}

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
