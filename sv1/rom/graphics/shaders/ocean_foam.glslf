#include "depth_utils.glslh"

in float log_z;
in vec3 world_position_out;
flat in vec3 normal_out;
in float foam_amount_out;
in float oil_spill_out;
in vec3 view_position_out;
in vec4 vertex_position_next_out;
in vec4 vertex_position_prev_out;

uniform vec3 underwater_color;

uniform sampler2D texture_depth;

uniform sampler2D texture_noise0;
uniform sampler2D texture_noise1;
uniform float noise_scroll_timer;
uniform vec3 world_offset;

out vec4 gnormal_light_factor_out;
out vec4 gcolor_out;
#if VELOCITY_ENABLED == 1
out vec2 gvelocity_out;
#endif

float sample_oil_factor()
{
    float oil_factor = oil_spill_out;

    vec2 noise_tex_coords0 = (world_position_out.xz - world_offset.xz) * 0.0004 + vec2(noise_scroll_timer, noise_scroll_timer) * 0.0007;
    vec2 noise_tex_coords1 = (world_position_out.zx - world_offset.zx) * 0.0008 - vec2(noise_scroll_timer, noise_scroll_timer) * 0.0004;

    vec4 noise_color0 = texture(texture_noise0, noise_tex_coords0);
    vec4 noise_color1 = texture(texture_noise1, noise_tex_coords1);
    vec4 noise_color = (noise_color0 * 0.3) + (noise_color1 * 0.5);

    oil_factor = (1.0 - (oil_factor * 0.5)) * (oil_factor * 2.0);
    //oil_factor = oil_factor + (oil_factor - (oil_factor * oil_factor * (3.0 - 2.0 * oil_factor)));

    return oil_factor * 1.25 + (noise_color.r - 0.75);
}

float sample_foam_factor()
{
    float water_depth = texelFetch(texture_depth, ivec2(gl_FragCoord.xy), 0).r;

    float foam_amount = 0;
    float distance_to_bottom = view_position_out.z - water_depth;
    float foam_distance_threshold = 0.8;
    if(distance_to_bottom < foam_distance_threshold)
    {
        float foam_factor = distance_to_bottom / foam_distance_threshold;
        foam_factor *= foam_factor;
        foam_amount = 1.0 - foam_factor;
    }

    foam_amount = max(foam_amount, foam_amount_out);
    foam_amount = mix(foam_amount, 0.0, smoothstep(0, 2500, -view_position_out.z));

    if((foam_amount > 0.0000001) && (-view_position_out.z < 2500.0))
    {
        vec2 noise_tex_coords0 = world_position_out.xz * 0.08 + vec2(noise_scroll_timer, noise_scroll_timer) * 0.07;
        vec2 noise_tex_coords1 = world_position_out.zx * 0.07 - vec2(noise_scroll_timer, noise_scroll_timer) * 0.04;

        vec4 noise_color0 = texture(texture_noise0, noise_tex_coords0);
        vec4 noise_color1 = texture(texture_noise1, noise_tex_coords1);
        vec4 noise_color = noise_color0 * 0.3 + noise_color1 * 0.5;

        float threshold = min(foam_amount, 0.25);
        threshold = foam_amount * 0.4;
        const float threshold_offset = 0.4;
        threshold = threshold_offset + (1.0 - threshold_offset) * threshold;
        threshold = 1.0 - threshold;

        if(noise_color.r > threshold)
        {
            return 1.0;
            
        }
    }

    return 0.0;
}

void main()
{
    gl_FragDepth = log_z_to_frag_depth(log_z);

#if VELOCITY_ENABLED == 1
    // Velocity
    vec2 screen_pos_next = (vertex_position_next_out.xy / vertex_position_next_out.w) * 0.5 + 0.5;
    vec2 screen_pos_prev = (vertex_position_prev_out.xy / vertex_position_prev_out.w) * 0.5 + 0.5;
    gvelocity_out = (screen_pos_next - screen_pos_prev);
#endif

    float oil_factor = sample_oil_factor();
    float foam_factor = sample_foam_factor();

    if(oil_factor <= 0.0 && foam_factor <= 0.0)
    {
        discard;
    }

    gcolor_out.rgb = mix(underwater_color, vec3(1.0), foam_factor * 0.4);
    gcolor_out.rgb = mix(gcolor_out.rgb, vec3(0.0, 0.0, 0.0), oil_factor);

    gnormal_light_factor_out = vec4(normalize(normal_out), 0.0);
}