shader_type canvas_item;
render_mode unshaded;

group_uniforms Feedback_Settings;
/**
 * Disable the shader effect.
 */
uniform bool disable = false;
/**
 * Texture containing the previous effect output. Defaults to [code]black[/code] so empty pixels have alpha=0 when unbound.
 */
uniform sampler2D previous_frame : hint_default_black;

/**
 * Time value for animating the fuzziness effect. If negative, uses TIME.
 */
uniform float time = -1.0;

group_uniforms Palette_Settings;
/**
 * 1×N strip of colors used for mapping. Import with filter: [code]Nearest[/code].
 */
uniform sampler2D palette_texture : filter_nearest;
/**
 * Optional alternate 1×N palette used for output colors.
 */
uniform sampler2D effect_palette_texture : filter_nearest;
/**
 * When enabled, output colors are taken from [code]effect_palette_texture[/code] instead of [code]palette_texture[/code].
 */
uniform bool use_effect_palette = false;
/**
 * Reverses input palette for mapping input to output palette color.
 */
uniform bool inverse_palette = false;

group_uniforms Mapping_Settings;
/**
 * Starting index within the input palette to consider.
 */
uniform int input_palette_offset = 0;
/**
 * Number of colors from [code]input_palette_offset[/code] to include. [code]-1[/code] (or ≤0) means until end.
 */
uniform int input_palette_range = -1;
/**
 * Starting index within the output/effect palette used for mapping.
 */
uniform int output_palette_offset = 0;
/**
 * Number of colors from [code]output_palette_offset[/code] to allow. [code]-1[/code] (or ≤0) means until end.
 */
uniform int output_palette_range = -1;
/**
 * When enabled, preserves relative index: output_id = output_offset + (input_id - input_offset).
 */
uniform bool map_palette_ids = true;

group_uniforms Flow_Settings;
/**
 * Horizontal flow component in [-1, 1]. The pixels flow in this direction per iteration. Through iteration_count, values < 1.0 accumulate until 1.0 to take effect.
 */
uniform float flow_direction_x : hint_range(-1.0, 1.0, 0.0001) = 0.0;
/**
 * Vertical flow component in [-1, 1]. The pixels flow in this direction per iteration. Through iteration_count, values < 1.0 accumulate until 1.0 to take effect.
 */
uniform float flow_direction_y : hint_range(-1.0, 1.0, 0.0001) = 1.0;
/**
 * Sub-steps per frame used to simulate multiple iterations per render step for low fps effects.
 */
uniform int iterations : hint_range(1, 100) = 1;
/**
 * Global iteration index used to stagger fractional flow over frames for non 1.0 flow values.
 */
uniform int iteration_count = 0;

group_uniforms Random_Settings;
/**
 * Base seed used for random sampling in decay/spawn decisions.
 */
uniform float random_seed : hint_range(0.0, 1000.0) = 0.0;
/**
 * Frequency parameter for random sampling function.
 */
uniform float random_frequency : hint_range(0.0, 100.0) = 100.0;
/**
 * Probability [0..1] that a valid input pixel spawns a trail on this step.
 */
uniform float spawn_chance : hint_range(0.0, 1.0) = 1.0;

group_uniforms Effect_Settings;
/**
 * Higher values resist decay; lower values advance decay faster.
 */
uniform float trail_persistence : hint_range(0.0, 1.0) = 0.5;
/**
 * Lateral diffusion amount. [code]>0[/code] adopts neighbors -> spreads to the sides; [code]<0[/code] forces edge decay -> shrinks from sides; [code]0[/code] disables spread.
 */
uniform float spread : hint_range(-1.0, 1.0, 0.0001) = 0.0;
/**
 * Allows input pixels with higher palette IDs to override decay feedback.
 */
uniform bool overlay_higher_colors = true;
/**
 * Limits spawning to the neighbor in the flow direction; useful for border-only effects.
 */
uniform bool only_edge_emit = false;
/**
 * Distance threshold (in pixels) from texture bounds where decay is forced.
 */
uniform int edge_pixel_size : hint_range(0, 100) = 2;

const int PALETTE_ID_NONE = -1;

#include "pixelart_utils.gdshaderinc"

varying flat int input_palette_size;
varying flat int effect_palette_size;

struct PaletteContext {
    vec3 cached_palette[MAX_PALETTE_SIZE];
    vec3 cached_effect_palette[MAX_PALETTE_SIZE];
    bool palette_loaded;
    bool effect_palette_loaded;
    int input_size;
    int output_size;
    int input_offset;
    int output_offset;
};

void ensure_palette_loaded(inout PaletteContext l_ctx) {
    if (l_ctx.palette_loaded) return;
    cache_palette(palette_texture, l_ctx.input_size, l_ctx.cached_palette);
    l_ctx.palette_loaded = true;
}

void ensure_output_palette_loaded(inout PaletteContext l_ctx) {
    if (use_effect_palette) {
        if (!l_ctx.effect_palette_loaded) {
            cache_palette(effect_palette_texture, l_ctx.output_size, l_ctx.cached_effect_palette);
            l_ctx.effect_palette_loaded = true;
        }
    } else {
        ensure_palette_loaded(l_ctx);
        l_ctx.cached_effect_palette = l_ctx.cached_palette;
    }
}

int get_feedback_id(vec3 l_color, inout PaletteContext l_palette_ctx) {
    ensure_output_palette_loaded(l_palette_ctx);
    return int(find_palette_id(l_color, l_palette_ctx.cached_effect_palette, l_palette_ctx.output_size).a);
}

int get_spread_feedback_id(vec4 l_right, vec4 l_left, inout PaletteContext l_palette_ctx) {
    if (l_right.a <= 0.0 && l_left.a <= 0.0) return PALETTE_ID_NONE;

    int l_right_id = (l_right.a > 0.0) ? get_feedback_id(l_right.rgb, l_palette_ctx) : PALETTE_ID_NONE;
    int l_left_id = (l_left.a > 0.0) ? get_feedback_id(l_left.rgb, l_palette_ctx) : PALETTE_ID_NONE;
    return max(l_right_id, l_left_id);
}

int process_spawn(int l_closest_id, inout PaletteContext l_palette_ctx) {
    ensure_output_palette_loaded(l_palette_ctx);
    return map_palette_ids ? (l_palette_ctx.output_offset + l_closest_id - l_palette_ctx.input_offset) : l_palette_ctx.output_offset;
}

int process_decay(int l_feedback_id, float l_decay_value, int l_max_id, bool l_force_decay) {
    if (l_feedback_id == PALETTE_ID_NONE) return PALETTE_ID_NONE;
    bool should_advance_decay = l_force_decay || l_decay_value >= trail_persistence;
    if (!should_advance_decay) return l_feedback_id;
    int l_next_id = l_feedback_id + 1;
    return (l_next_id > l_max_id) ? PALETTE_ID_NONE : l_next_id;
}

int process_iteration(sampler2D l_texture, float l_time, ivec2 base_uv_pos, int step_offset, vec2 texture_size, vec4 last_iteration_color, PaletteContext palette_ctx, int max_output_id, int effective_range, int output_effective_range) {
    ivec2 lookup_uv_pos = base_uv_pos + ivec2(int(flow_direction_x * float(step_offset - 1)), int(flow_direction_y * float(step_offset - 1)));
    ivec2 flow_shifted_uv = lookup_uv_pos + ivec2(int(flow_direction_x), int(flow_direction_y));

    int global_iteration_index = iteration_count * iterations - step_offset;
    if (abs(flow_direction_x) < 1.0 && abs(flow_direction_x) > 0.01) {
        int modulator = int(round(1.0 / abs(flow_direction_x)));
        int iteration_mod = global_iteration_index - (global_iteration_index / modulator) * modulator;
        if (iteration_mod == 0) {
            flow_shifted_uv.x += int(sign(flow_direction_x));
        }
    }
    if (abs(flow_direction_y) < 1.0 && abs(flow_direction_y) > 0.01) {
        int modulator = int(round(1.0 / abs(flow_direction_y)));
        int iteration_mod = global_iteration_index - (global_iteration_index / modulator) * modulator;
        if (iteration_mod == 0) {
            flow_shifted_uv.y += int(sign(flow_direction_y));
        }
    }

    vec4 previous_frame_color = (step_offset == iterations) ?
        ((flow_shifted_uv.y >= int(texture_size.y)) ? vec4(0.0) : texelFetch(previous_frame, flow_shifted_uv, 0)) :
        last_iteration_color;
    vec4 current_pixel_color = texelFetch(l_texture, lookup_uv_pos, 0);

    ivec2 flow_forward_offset = ivec2(0, 1);
    ivec2 flow_left_offset = ivec2(-1, 0);
    ivec2 flow_right_offset = ivec2(1, 0);
    if (abs(flow_direction_x) > abs(flow_direction_y)) {
        flow_left_offset = ivec2(0, -1);
        flow_right_offset = ivec2(0, 1);
        if (flow_direction_x > 0.0) {
            flow_forward_offset = ivec2(1, 0);
        } else {
            flow_forward_offset = ivec2(-1, 0);
        }
    } else {
        if (flow_direction_y > 0.0) {
            flow_forward_offset = ivec2(0, 1);
        } else {
            flow_forward_offset = ivec2(0, -1);
        }
    }

    bool has_spread_effect = abs(spread) > 0.0001;
    vec4 previous_frame_right = vec4(0.0);
    vec4 previous_frame_left = vec4(0.0);
    if (has_spread_effect && step_offset == iterations) {
        previous_frame_right = texelFetch(previous_frame, flow_shifted_uv + flow_right_offset, 0);
        previous_frame_left = texelFetch(previous_frame, flow_shifted_uv + flow_left_offset, 0);
    }

    vec2 seed = vec2(float(lookup_uv_pos.x) / texture_size.x, float(lookup_uv_pos.y) / texture_size.y) + vec2(0.1 * random_seed, 0.001 * random_seed);
    float decay_value = random(seed, random_frequency, l_time + seed.x * 10.0);

    float dist_to_edge = min(
        min(seed.x, 1.0 - seed.x) * texture_size.x,
        min(seed.y, 1.0 - seed.y) * texture_size.y
    );
    float min_decay = step(dist_to_edge, float(edge_pixel_size));
    decay_value = clamp(decay_value, min_decay, 1.0);

    float spawn_value = random(seed + vec2(0.2 * random_seed, 0.003 * random_seed), random_frequency, l_time + 10.0 * (1.0 - seed.x));

    int output_palette_id = PALETTE_ID_NONE;
    bool has_current_pixel = current_pixel_color.a > 0.0;
    bool has_previous_pixel = previous_frame_color.a == 1.0;
    bool can_decay_pixel = decay_value > -1.0;

    if (has_current_pixel) {
        if (!only_edge_emit) {
            ensure_palette_loaded(palette_ctx);
            int matched_input_palette_id = int(find_palette_id(current_pixel_color.rgb, palette_ctx.cached_palette, input_palette_size).a);
            if (inverse_palette) {
                matched_input_palette_id = input_palette_size - matched_input_palette_id - 1;
            }
            bool is_in_input_range = matched_input_palette_id >= palette_ctx.input_offset && matched_input_palette_id < palette_ctx.input_offset + effective_range;
            if (is_in_input_range) {
                if (spawn_value <= spawn_chance && spawn_chance > 0.0) {
                    output_palette_id = process_spawn(matched_input_palette_id, palette_ctx);
                }
                can_decay_pixel = false;
            }
            if (has_previous_pixel) {
                int previous_palette_id = get_feedback_id(previous_frame_color.rgb, palette_ctx);
                if ((output_palette_id == PALETTE_ID_NONE || output_palette_id > previous_palette_id) && (matched_input_palette_id >= previous_palette_id || overlay_higher_colors)) {
                    if (matched_input_palette_id == previous_palette_id && is_in_input_range) {
                        decay_value = 0.0;
                    }
                    if (previous_palette_id > PALETTE_ID_NONE) {
                        float spread_modifier = 1.0 - float(previous_palette_id - palette_ctx.output_offset) / float(output_effective_range);
                	    spread_modifier = spread_modifier * trail_persistence;
                        bool force_edge_decay = has_spread_effect && spread < 0.0 &&
                            (previous_frame_right.a == 0.0 || previous_frame_left.a == 0.0) &&
                            decay_value < abs(spread * spread_modifier);
                        output_palette_id = process_decay(previous_palette_id, decay_value, max_output_id, force_edge_decay);
                    } else {
                        output_palette_id = PALETTE_ID_NONE;
                    }
                }
            } else if (can_decay_pixel && has_spread_effect && spread > 0.0) {
                int previous_palette_id = get_spread_feedback_id(previous_frame_right, previous_frame_left, palette_ctx);
				if (previous_palette_id > PALETTE_ID_NONE) {
					float spread_modifier = 1.0 - float(previous_palette_id - palette_ctx.output_offset) / float(output_effective_range);
                	spread_modifier = spread_modifier * trail_persistence;
                    output_palette_id = (decay_value <= abs(spread * spread_modifier)) ? previous_palette_id : PALETTE_ID_NONE;
                }
            }
        }
    } else if (has_previous_pixel) {
        int previous_palette_id = get_feedback_id(previous_frame_color.rgb, palette_ctx);
        float spread_modifier = 1.0 - float(previous_palette_id - palette_ctx.output_offset) / float(output_effective_range);
        spread_modifier = spread_modifier * trail_persistence;
		bool force_edge_decay = has_spread_effect && spread < 0.0 &&
            (previous_frame_right.a == 0.0 || previous_frame_left.a == 0.0) &&
            decay_value < abs(spread * spread_modifier);
        output_palette_id = process_decay(previous_palette_id, decay_value, max_output_id, force_edge_decay);
    } else {
        if (has_spread_effect && spread > 0.0) {
            int previous_palette_id = get_spread_feedback_id(previous_frame_right, previous_frame_left, palette_ctx);
			if (previous_palette_id > PALETTE_ID_NONE) {
				float spread_modifier = 1.0 -float(previous_palette_id - palette_ctx.output_offset) / float(output_effective_range);
            	spread_modifier = spread_modifier * trail_persistence;
                output_palette_id = (decay_value < abs(spread * spread_modifier)) ? previous_palette_id : PALETTE_ID_NONE;
            }
        }
        if (only_edge_emit) {
            vec4 neighbor_pixel_color = vec4(0.0);
            if (abs(flow_forward_offset.y) >= abs(flow_forward_offset.x)) {
                if (lookup_uv_pos.y + int(flow_forward_offset.y) < int(texture_size.y) && lookup_uv_pos.y + int(flow_forward_offset.y) >= 0) {
                    neighbor_pixel_color = texelFetch(l_texture, lookup_uv_pos + flow_forward_offset, 0);
                }
            } else {
                if (lookup_uv_pos.x + int(flow_forward_offset.x) < int(texture_size.x) && lookup_uv_pos.x + int(flow_forward_offset.x) >= 0) {
                    neighbor_pixel_color = texelFetch(l_texture, lookup_uv_pos + flow_forward_offset, 0);
                }
            }

            if (neighbor_pixel_color.a > 0.0) {
                ensure_palette_loaded(palette_ctx);
                int matched_input_palette_id = int(find_palette_id(neighbor_pixel_color.rgb, palette_ctx.cached_palette, input_palette_size).a);
                if (inverse_palette) {
                    matched_input_palette_id = input_palette_size - matched_input_palette_id - 1;
                }
                bool is_in_input_range = matched_input_palette_id >= palette_ctx.input_offset && matched_input_palette_id < palette_ctx.input_offset + effective_range;
                if (is_in_input_range) {
                    if (spawn_value <= spawn_chance) {
                        output_palette_id = process_spawn(matched_input_palette_id, palette_ctx);
                    }
                }
            }
        }
    }

    return output_palette_id;
}

void vertex() {
    input_palette_size = get_palette_size(palette_texture);
    effect_palette_size = get_palette_size(effect_palette_texture);
}

void fragment() {
    if (disable) {
        discard;
    } else {
        vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
        ivec2 fragment_uv_pos = ivec2(UV * texture_size);

        PaletteContext palette_ctx;
        palette_ctx.palette_loaded = false;
        palette_ctx.effect_palette_loaded = false;
        palette_ctx.input_size = input_palette_size;
        palette_ctx.output_size = use_effect_palette ? effect_palette_size : input_palette_size;
        palette_ctx.input_offset = input_palette_offset;
        palette_ctx.output_offset = output_palette_offset;

        int effective_range = (input_palette_range > 0) ?
            min(input_palette_range + input_palette_offset, input_palette_size) - input_palette_offset :
            input_palette_size - input_palette_offset;
        if (inverse_palette) {
            palette_ctx.input_offset = input_palette_size - effective_range - input_palette_offset;
        }
        int output_effective_range = (output_palette_range > 0) ?
            min(output_palette_range + output_palette_offset, palette_ctx.output_size) - output_palette_offset :
            palette_ctx.output_size - output_palette_offset;
        int max_output_id = min(palette_ctx.output_size - 1, output_effective_range + output_palette_offset - 1);

        int output_palette_id = PALETTE_ID_NONE;
        vec4 current_iteration_color = vec4(0.0);

        for (int step = iterations; step >= 1; step--) {
            float use_time = time;
            if (time < 0.0) use_time = TIME;
            output_palette_id = process_iteration(TEXTURE, use_time, fragment_uv_pos, step, texture_size, current_iteration_color, palette_ctx, max_output_id, effective_range, output_effective_range);
            if (output_palette_id >= 0) {
                ensure_output_palette_loaded(palette_ctx);
                current_iteration_color = vec4(palette_ctx.cached_effect_palette[output_palette_id], 1.0);
            } else {
                current_iteration_color = vec4(0.0);
            }
        }

        if (output_palette_id >= 0 && output_palette_id < palette_ctx.output_size) {
            ensure_output_palette_loaded(palette_ctx);
            COLOR = vec4(palette_ctx.cached_effect_palette[output_palette_id], 1.0);
        } else {
            discard;
        }
    }
}
