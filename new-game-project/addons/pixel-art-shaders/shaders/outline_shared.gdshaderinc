#include "pixelart_utils.gdshaderinc"

varying flat int actual_palette_size;

find_majority_palette_id(25)

float compute_noise_threshold(vec2 l_uv, vec2 l_texture_size, float l_random_fragmentation, bool l_time_shift, float l_time_speed, sampler2D l_noise_texture, float l_noise_scale, bool l_doubles, float l_time) {
	vec2 texel_uv = (floor(l_uv * l_texture_size * l_random_fragmentation) / l_texture_size) / l_random_fragmentation;
	vec2 noise_uv = texel_uv * l_noise_scale;
	if (l_time_shift) {
		noise_uv += vec2(l_time * l_time_speed * 0.001, l_time * l_time_speed * 0.01);
	}

	ivec2 noise_texture_size = textureSize(l_noise_texture, 0);
	ivec2 noise_coords = ivec2(noise_uv * vec2(noise_texture_size)) % noise_texture_size;
	float raw_noise_value = texelFetch(l_noise_texture, noise_coords, 0).r;

	float noise_value = raw_noise_value * raw_noise_value;
	if (noise_value > 0.0) {
		float log_val = log2(noise_value);
		float rounded_log = ceil(log_val);
		noise_value = pow(2.0, rounded_log);
		noise_value = min(noise_value, 1.0);
	}

	return l_doubles ? pow(1.0 - raw_noise_value, 1.0) * 8.0 : pow(1.0 - raw_noise_value, 1.0) * 7.0 + 1.0;
}

float compute_cursor_threshold(vec2 l_uv, vec2 l_cursor_position, float l_cursor_radius_pixels, float l_cursor_border_radius_pixels, float l_cursor_max_threshold, bool l_doubles, vec2 l_texture_size, bool l_inverse) {
	vec2 texel_uv = floor(l_uv * l_texture_size) / l_texture_size;

	vec2 delta_uv = texel_uv - floor(l_cursor_position * l_texture_size) / l_texture_size;
	vec2 delta_pixels = delta_uv * l_texture_size;
	float distance_pixels = length(delta_pixels);

	float inner_threshold, outer_threshold, threshold_value;

	if (l_inverse) {
		inner_threshold = l_cursor_max_threshold;
		outer_threshold = l_doubles ? 0.0 : 1.0;
	} else {
		inner_threshold = l_doubles ? 0.0 : 1.0;
		outer_threshold = l_cursor_max_threshold;
	}

	if (distance_pixels <= l_cursor_radius_pixels) {
		return inner_threshold;
	}

	if (distance_pixels >= l_cursor_border_radius_pixels) {
		return outer_threshold;
	}

	float normalized_distance = (distance_pixels - l_cursor_radius_pixels) / (l_cursor_border_radius_pixels - l_cursor_radius_pixels);

	if (l_inverse) {
		normalized_distance = 1.0 - normalized_distance;
	}
	if (l_doubles) {
		threshold_value = normalized_distance * (l_cursor_max_threshold - 1.0) + 1.0;
	} else {
		threshold_value = normalized_distance * (l_cursor_max_threshold - 2.0) + 2.0;
	}
	return threshold_value;
}

void vertex() {
	actual_palette_size = get_palette_size(palette_texture);
}

void fragment() {
	bool disable_override = disable;
	vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 offset = offset_scale / texture_size;

	vec3 cached_palette[MAX_PALETTE_SIZE];
	cache_palette(palette_texture, actual_palette_size, cached_palette);

	ivec2 main_texture_size = textureSize(TEXTURE, 0);
	vec2 center_coords = UV * vec2(main_texture_size);
	vec2 offset_pixels = offset * vec2(main_texture_size);

	vec4 pixel_orig[25];
	vec4 pixel[25];
	int pixel_id[25];
	sample_5x5_grid(TEXTURE, center_coords, offset_pixels, pixel_orig);

	find_pixels_to_palette(pixel_orig, cached_palette, actual_palette_size, pixel, pixel_id);

	int transparent_count = 0;
	for (int i = 0; i < 25; i++) {
		if (pixel_orig[i].a < 0.1) { transparent_count++; }
	}

	if (transparent_count >= 25) {
		discard;
	}

	MajorityPaletteResult majority_result = find_majority_palette_id_25(pixel_id, pixel_orig, actual_palette_size);
	int majority_palette_id = majority_result.palette_id;

	if (pixel_orig[12].a < 0.1 || pixel_id[12] == -1) {
		pixel_id[12] = -1;
		pixel[12] = vec4(cached_palette[majority_palette_id], 1.0);
		if (keep_border_colors) {
			disable_override = true;
		}
	}

	NeighborAnalysis neighbor_analysis;
	float palette_jump_threshold = doubles ? 0.0 : 1.0;
	if (!disable_override) {
		neighbor_analysis = analyze_neighbors_8(pixel_id, pixel_orig, pixel_id[12], palette_diff_threshold);

		#ifdef WOBBLE_ENABLED
		float use_time = time;
		if (time < 0.0) { use_time = TIME; }
		palette_jump_threshold = compute_noise_threshold(UV, texture_size, random_fragmentation, time_shift, time_speed, noise_texture, noise_scale, doubles, use_time);
		#elif defined(CURSOR_ENABLED)
		palette_jump_threshold = compute_cursor_threshold(UV, cursor_position, cursor_radius, cursor_border_radius, cursor_max_threshold, doubles, texture_size, cursor_inverse);
		if (palette_jump_threshold >= cursor_max_threshold) {
			disable_override = true;
		}
		palette_jump_threshold = floor(palette_jump_threshold);
		#endif

		if (pixel_id[4] == -1 && neighbor_analysis.transparent_neighbors == 8) {
            disable_override = true;
        }
	}

	if (!disable_override && !(neighbor_analysis.border_pixel && keep_border_colors)) {
		if (pixel_id[12] == -1) {
			if (8.0 - float(neighbor_analysis.transparent_neighbors) > palette_jump_threshold) {
				COLOR = vec4(cached_palette[majority_palette_id], 1.0);
			} else {
				COLOR = pixel_orig[12];
			}
		} else {
			if (neighbor_analysis.palette_offset > palette_jump_threshold) {
				int new_palette_id = min(pixel_id[12] + neighbor_analysis.min_diff, actual_palette_size - 1);
				vec3 new_color = cached_palette[new_palette_id];
				COLOR = vec4(new_color, neighbor_analysis.transparent_neighbors > int(palette_jump_threshold) && (pixel_orig[12].a <= 0.1) ? 0.0 : 1.0);
			} else if (neighbor_analysis.palette_offset < -palette_jump_threshold) {
				int new_palette_id = max(pixel_id[12] - neighbor_analysis.min_diff, 0);
				vec3 new_color = cached_palette[new_palette_id];
				COLOR = vec4(new_color, neighbor_analysis.transparent_neighbors > int(palette_jump_threshold) && (pixel_orig[12].a <= 0.1) ? 0.0 : 1.0);
			} else {
				COLOR = pixel_orig[12];
			}
		}
	} else {
		COLOR = pixel_orig[12];
	}
}
