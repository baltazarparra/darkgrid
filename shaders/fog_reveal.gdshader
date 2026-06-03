shader_type canvas_item;

uniform vec2 player_screen_uv = vec2(0.5, 0.5);
uniform float reveal_radius_uv = 0.1;
uniform float edge_softness = 0.08;

void fragment() {
	float d = distance(SCREEN_UV, player_screen_uv);
	// Variação sutil na borda — simula névoa viva, não círculo geométrico
	float pulse = sin(TIME * 1.2) * 0.004 + sin(TIME * 2.7 + SCREEN_UV.x * 8.0) * 0.003;
	float alpha = smoothstep(reveal_radius_uv + pulse, reveal_radius_uv + edge_softness + pulse, d);
	COLOR = vec4(0.05, 0.04, 0.06, alpha * 0.92);
}
