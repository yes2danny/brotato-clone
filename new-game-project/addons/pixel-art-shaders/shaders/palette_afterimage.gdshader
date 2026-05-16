shader_type canvas_item;

/**
 * Texture containing the color palette.
 */
uniform sampler2D palette_texture : filter_nearest;
/**
 * Inverts the palette color selection logic for the afterimage effect.
 */
uniform bool inverse_palette = false;
/**
 * Starting offset in the palette for afterimage colors.
 */
uniform int palette_offset = 0;
/**
 * Number of palette colors to use for the afterimage trail. 0 means all colors from offset to end.
 */
uniform int palette_range = 0;
/**
 * Starting index in the palette for the active color range filter.
 */
uniform int active_palette_offset = 0;
/**
 * Number of palette colors to include in the active range filter. 0 means all colors from offset to end.
 */
uniform int active_palette_range = 0;
/**
 * Only show afterimage for pixels matching colors in the active palette range.
 */
uniform bool only_active_colors = false;
/**
 * Distance in pixels from the sprite center for the afterimage rotation.
 */
uniform float rotation_radius = 2.0;
/**
 * Variation in radius across the afterimage trail. 0 = uniform radius, 1 = full variation from 0 to rotation_radius.
 */
uniform float radius_variation: hint_range(0.0, 1.0) = 0.0;
/**
 * Speed multiplier for the afterimage rotation animation.
 */
uniform float rotation_speed = 1.0;
/**
 * Enables pixel-perfect rendering for the afterimage positions.
 */
uniform bool pixel_perfect = true;
/**
 * Normalized rotation progress (0.0–1.0). When set to a value <= 1.0, controls rotation position manually.
 * 0.0 = start position, 1.0 = completes one full rotation back to start. Values > 1.0 use TIME-based animation.
 */
uniform float time : hint_range(0.0, 1.1) = 1.1;


#include "pixelart_utils.gdshaderinc"

varying flat int actual_palette_size;

void vertex() {
	actual_palette_size = get_palette_size(palette_texture);
}

void fragment() {
	vec4 final_color = COLOR;

	if (COLOR.a == 0.0) {
		float rotation_angle;
		if (time <= 1.0 && time != -1.0) {
			rotation_angle = time * TAU;
		} else {
			rotation_angle = TIME * rotation_speed;
		}
		vec3 cached_palette[MAX_PALETTE_SIZE];
		bool palette_loaded = false;
		vec2 center = vec2(0.5, 0.5);
		int effective_range = (palette_range > 0) ? min(palette_range + palette_offset, actual_palette_size) - palette_offset : actual_palette_size - palette_offset;
		int active_effective_range = (active_palette_range > 0) ? min(active_palette_range + active_palette_offset, actual_palette_size) - active_palette_offset : actual_palette_size - active_palette_offset;
		for (int i = 0; i < effective_range; i++) {
			float angle = -( TAU / float(effective_range)) * float(i) + rotation_angle;

			float scale_factor = 1.0;
			if (effective_range > 1) scale_factor = (1.0 - radius_variation) + (radius_variation * (float(i) / float(effective_range - 1)));
			float current_radius = rotation_radius * scale_factor;
			vec2 rotation_offset = vec2(cos(angle), sin(angle)) * current_radius;;
			if (pixel_perfect) {
				rotation_offset = floor(rotation_offset + 0.5);
			}
			vec2 offset_uv = UV + (rotation_offset * TEXTURE_PIXEL_SIZE);

			vec4 afterimage = texture(TEXTURE, offset_uv);

			if (afterimage.a > 0.0) {
				bool valid_palette_color = true;
				if (only_active_colors) {
					if (!palette_loaded) {
						cache_palette(palette_texture, actual_palette_size, cached_palette);
						palette_loaded = true;
					}
					vec4 palette_color = find_palette_id(afterimage.rgb, cached_palette, MAX_PALETTE_SIZE);

					if (inverse_palette) {
						if (int(palette_color.a) >= actual_palette_size - active_palette_offset) valid_palette_color = false;
						if (int(palette_color.a) < actual_palette_size - (active_palette_offset + active_effective_range)) valid_palette_color = false;
					} else {
						if (int(palette_color.a) < active_palette_offset) valid_palette_color = false;
						if (int(palette_color.a) >= active_palette_offset + active_effective_range) valid_palette_color = false;
					}
				}
				if (valid_palette_color || !only_active_colors) {
					int base_index = inverse_palette ? (actual_palette_size - palette_offset - i - 1) : i + palette_offset;
					int palette_index = clamp(base_index, 0, actual_palette_size - 1);
					afterimage.rgb = texelFetch(palette_texture, ivec2(palette_index, 0), 0).rgb;
					final_color = afterimage;
					break;
				}
			}
		}
	}

	COLOR = final_color;
}
