shader_type canvas_item;

uniform vec2 player_screen_uv = vec2(0.5, 0.5);
uniform float reveal_radius_uv = 0.1;
uniform float edge_softness = 0.025;

void fragment() {
	float d = distance(SCREEN_UV, player_screen_uv);
	float alpha = smoothstep(reveal_radius_uv, reveal_radius_uv + edge_softness, d);
	COLOR = vec4(0.05, 0.04, 0.06, alpha * 0.92);
}
