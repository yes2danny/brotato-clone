shader_type canvas_item;

/**
 * Noise texture used as a source of pseudo-random values for computing palette jump thresholds. Should be a tiled noise texture.
 */
uniform sampler2D noise_texture : repeat_enable, filter_linear;
/**
 * Scales the coordinate space used when sampling the noise texture. Values < 1 zoom in on the noise, values > 1 tile the noise more densely. Typical range is 0.1 - 10.0.
 */
uniform float noise_scale : hint_range(0.01, 10.0) = 1.0;
/**
 * Texture containing the color palette.
 */
uniform sampler2D palette_texture : filter_nearest;
/**
 * Whether to shift each pixel's color along the palette during the dissolve.
 * Enable to remap colors over time; disable to only mask pixels without recoloring.
 */
uniform bool palette_shift = true;
/**
 * Reverses the palette shift direction.
 * When true, colors move toward lower palette indices; otherwise toward higher indices.
 */
uniform bool inverse_palette_shift = false;

/**
 * Level of pixelization for the dissolve effect. Higher values make the dissolve pixels larger.
 */
uniform int pixelization : hint_range(0, 6) = 0;
/**
 * Normalized dissolve progress for manual control from scripts (0.0–1.0).
 * Use when not relying on the built-in TIME progression.
 */
uniform float time : hint_range(0.0, 1.1) = 1.1;
/**
 * Thickness of the tinted dissolve edge band (0.0–1.0).
 * Higher values produce a wider rim around the dissolving area.
 */
uniform float dissolve_border_size : hint_range(0.0, 1.0) = 0.1;

/**
 * Enables color tinting along the dissolve edge.
 * When true, blends between dissolve_color_from and dissolve_color_to over progress.
 */
uniform bool use_dissolve_color = false;
/**
 * Starting tint color for the dissolve gradient.
 * Interpolates toward dissolve_color_to as progress increases.
 */
uniform vec4 dissolve_color_from : source_color = vec4(0.0, 0.0, 0.0, 0.0);
/**
 * Ending tint color for the dissolve gradient.
 * Reached when dissolve progress is 1.0.
 */
uniform vec4 dissolve_color_to : source_color = vec4(0.0, 0.0, 0.0, 0.0);
/**
 * Overall intensity multiplier for the dissolve tint (0.0–5.0).
 * Higher values produce a stronger color influence.
 */
uniform float dissolve_color_strength : hint_range(0.0, 5.0) = 0.5;

varying flat int actual_palette_size;
varying flat float fragmentation_scale;


#include "pixelart_utils.gdshaderinc"

float get_noise_value(vec2 l_uv, vec2 l_texture_size, float l_pixelization, sampler2D l_noise_texture, float l_noise_scale) {
	vec2 texel_uv = (floor(l_uv * l_texture_size * l_pixelization) / l_texture_size) / l_pixelization;
	vec2 noise_uv = texel_uv * l_noise_scale;
	ivec2 noise_texture_size = textureSize(l_noise_texture, 0);
	ivec2 noise_coords = ivec2(noise_uv * vec2(noise_texture_size)) % noise_texture_size;
	float raw_noise_value = texelFetch(l_noise_texture, noise_coords, 0).r;
	return raw_noise_value;
}

void vertex() {
	actual_palette_size = get_palette_size(palette_texture);
	fragmentation_scale = pow(2.0, float(-pixelization));
}

void fragment() {
	if (COLOR.a <= 0.0) discard;

	vec3 cached_palette[MAX_PALETTE_SIZE];
	cache_palette(palette_texture, actual_palette_size, cached_palette);

	vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
	float raw_progress = mod(TIME, 1.0);
	if (time <= 1.0 && time != -1.0) raw_progress = time;
	float progress = smoothstep(0.0, 1.0, raw_progress);
	progress *= 1.0 + dissolve_border_size;
	progress -= dissolve_border_size;


	float noise_value = get_noise_value(UV, texture_size, fragmentation_scale, noise_texture, noise_scale);
	if (noise_value <= progress) discard;
	if (noise_value - dissolve_border_size <= progress) {
		vec3 new_color = COLOR.rgb;
		if (palette_shift) {
			vec4 result = find_palette_id(new_color, cached_palette, actual_palette_size);
			float palette_id = result.a;
			float new_palette_id = 0.0;
			if (inverse_palette_shift) {
				new_palette_id = palette_id - palette_id * raw_progress;
			} else {
				new_palette_id = palette_id + (float(actual_palette_size) - palette_id) * raw_progress;
			}
			new_palette_id = clamp(new_palette_id, 0.0, float(actual_palette_size));
			new_color = cached_palette[int(new_palette_id)];
		}
		if (use_dissolve_color) {
			new_color += mix(dissolve_color_from.rgb, dissolve_color_to.rgb, raw_progress) * dissolve_color_strength * raw_progress;
			float max_color = max(max(new_color.r, new_color.g), new_color.b);
			if (max_color > 1.0) {
				new_color -= max_color - 1.0;
			}
		}
		COLOR = vec4(new_color, COLOR.a);
	}
}
