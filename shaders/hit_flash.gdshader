shader_type canvas_item;

// Flash branco de impacto: mix da textura para branco puro pelo uniform.
// modulate overbright (2,2,2) não alcança branco em pixels escuros no
// gl_compatibility — o mix alcança. flash_amount 0 = sprite intacto.
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = vec4(mix(tex.rgb, vec3(1.0), flash_amount), tex.a) * COLOR;
}
