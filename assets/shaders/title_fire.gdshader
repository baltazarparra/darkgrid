shader_type canvas_item;

// Efeito dark fire pixelado para o título CAIPORA.
// NÃO lê SCREEN_TEXTURE — compatível com gl_compatibility/web.

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.1) {
		COLOR = vec4(0.0);
		return;
	}
	// Quantização em blocos 1/8 do UV — look pixelado de pixel-art
	vec2 px = floor(UV * 8.0) / 8.0;
	// Ruído determinístico por bloco, animado no tempo
	float noise = fract(sin(dot(px, vec2(12.9898, 78.233)) + TIME * 2.5) * 43758.545);
	// t=0 no topo (chama viva), t=1 na base (brasa escura)
	float t = clamp(UV.y * 1.4 + noise * 0.35 - 0.2, 0.0, 1.0);
	// Paleta dark fire — mesma progressão do DoomFire
	vec3 hot   = vec3(1.00, 0.55, 0.05);
	vec3 mid   = vec3(0.85, 0.30, 0.00);
	vec3 dark  = vec3(0.41, 0.05, 0.00);
	vec3 ember = vec3(0.15, 0.00, 0.00);
	vec3 fire;
	if (t < 0.33)
		fire = mix(hot,  mid,   t / 0.33);
	else if (t < 0.66)
		fire = mix(mid,  dark,  (t - 0.33) / 0.33);
	else
		fire = mix(dark, ember, (t - 0.66) / 0.34);
	COLOR = vec4(fire, tex.a);
}
