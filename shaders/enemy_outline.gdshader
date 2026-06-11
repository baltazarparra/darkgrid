shader_type canvas_item;

// Outer glow para legibilidade de sprites contra fundos escuros.
// Detecta bordas do sprite amostrando vizinhos em pixel-space.

uniform vec4 glow_color : source_color = vec4(0.9, 0.85, 0.75, 0.65);
uniform float glow_thickness_px : hint_range(0.0, 8.0) = 2.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 out_color = tex * COLOR;
	if (tex.a < 0.1) {
		vec2 ps = vec2(1.0) / vec2(textureSize(TEXTURE, 0));
		float t = glow_thickness_px;
		float neighbor_alpha =
			texture(TEXTURE, UV + vec2(t * ps.x, 0.0)).a +
			texture(TEXTURE, UV + vec2(-t * ps.x, 0.0)).a +
			texture(TEXTURE, UV + vec2(0.0, t * ps.y)).a +
			texture(TEXTURE, UV + vec2(0.0, -t * ps.y)).a;
		if (neighbor_alpha > 0.0) {
			out_color = glow_color;
		}
	}
	COLOR = out_color;
}
