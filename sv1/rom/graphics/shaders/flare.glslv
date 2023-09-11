#include "depth_utils.glslh"

in vec3 vertex_position_in;
in vec2 vertex_uv_in;
in vec3 vertex_normal_in;
in vec4 vertex_color_in;

out float log_z;
out vec2 vertex_uv_out;
out vec3 vertex_world_position_out;
out vec4 vertex_position_prev_out;
out vec4 vertex_position_next_out;
out vec3 vertex_normal_out;
out vec4 vertex_color_out;

uniform mat4 mat_view_proj;
uniform mat4 mat_view_proj_prev;
uniform mat4 mat_view_proj_next;
uniform mat4 mat_world;
uniform vec3 main_light_color;

void main()
{
	vec4 world_pos = mat_world * vec4(vertex_position_in, 1.0);
	vertex_world_position_out = world_pos.xyz;

	//No prev/next world matrices
	vertex_position_prev_out = mat_view_proj_prev * world_pos;
	vertex_position_next_out = mat_view_proj_next * world_pos;

	vertex_normal_out = vertex_normal_in;

	vertex_uv_out = vertex_uv_in;
	vertex_color_out = vertex_color_in;

	gl_Position = mat_view_proj * world_pos;
	encode_depth(gl_Position, log_z);
}