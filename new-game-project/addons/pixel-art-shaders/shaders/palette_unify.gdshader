shader_type canvas_item;

uniform sampler2D palette_texture : filter_nearest;
uniform float blend_strength : hint_range(0.0, 1.0) = 1.0;

#include "pixelart_utils.gdshaderinc"

varying flat int actual_palette_size;

void vertex() {
	actual_palette_size = get_palette_size(palette_texture);
}

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	if (original.a < 0.1) {
		COLOR = original;
	} else {
		vec3 cached_palette[MAX_PALETTE_SIZE];
		cache_palette(palette_texture, actual_palette_size, cached_palette);
		vec4 closest = find_closest_palette_color_and_id(original.rgb, cached_palette, actual_palette_size);
		COLOR = vec4(mix(original.rgb, closest.rgb, blend_strength), original.a);
	}
}
