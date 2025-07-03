shader_type canvas_item;

uniform float offset_amount = 15.0;
uniform float time_speed = 1.0;
uniform float direct_uv_offset = 0.005;

void fragment() {
	vec2 uv_offset1 = vec2(offset_amount * sin(TIME * time_speed), offset_amount * sin(TIME * time_speed));
	vec2 uv_offset2 = vec2(-offset_amount * sin(TIME * time_speed), -offset_amount * sin(TIME * time_speed));

	vec4 base = texture(TEXTURE, UV);
	vec4 ghost1 = texture(TEXTURE, UV + uv_offset1 * direct_uv_offset) * 0.5;
	vec4 ghost2 = texture(TEXTURE, UV + uv_offset2 * direct_uv_offset) * 0.5;

	COLOR = base + ghost1 + ghost2;
}
