shader_type canvas_item;

// Flash branco de impacto: mix da textura para branco puro pelo uniform.
// modulate overbright (2,2,2) não alcança branco em pixels escuros no
// gl_compatibility — o mix alcança. flash_amount 0 = sprite intacto.
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform bool outline_enabled = true;
uniform vec4 outline_color : source_color = vec4(0.92, 0.78, 0.52, 0.82);
uniform float outline_thickness_px : hint_range(0.0, 8.0) = 2.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 out_color = vec4(mix(tex.rgb, vec3(1.0), flash_amount), tex.a) * COLOR;
	if (outline_enabled && tex.a < 0.1) {
		vec2 ps = vec2(1.0) / vec2(textureSize(TEXTURE, 0));
		float t = outline_thickness_px;
		float neighbor_alpha =
			texture(TEXTURE, UV + vec2(t * ps.x, 0.0)).a +
			texture(TEXTURE, UV + vec2(-t * ps.x, 0.0)).a +
			texture(TEXTURE, UV + vec2(0.0, t * ps.y)).a +
			texture(TEXTURE, UV + vec2(0.0, -t * ps.y)).a;
		if (neighbor_alpha > 0.0) {
			out_color = outline_color;
		}
	}
	COLOR = out_color;
}
