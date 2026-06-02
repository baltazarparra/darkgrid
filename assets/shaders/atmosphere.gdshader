shader_type canvas_item;
render_mode blend_mix;

// Atmosfera de horror folk: vinheta escura + grão de filme animado.
// NÃO lê SCREEN_TEXTURE (custo/instabilidade em gl_compatibility no web) —
// desenha por cima. Color-grade global fica a cargo do CanvasModulate.

uniform float vignette_inner : hint_range(0.0, 1.0) = 0.55;
uniform float vignette_outer : hint_range(0.0, 1.6) = 1.05;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.82;
uniform vec3 vignette_color : source_color = vec3(0.02, 0.0, 0.0);
uniform float grain_strength : hint_range(0.0, 0.4) = 0.06;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	// distância normalizada do centro (0 no centro, ~1 nos cantos)
	float d = distance(UV, vec2(0.5)) * 1.41421356;
	float vig = smoothstep(vignette_inner, vignette_outer, d) * vignette_opacity;

	// grão: ruído por pixel, deslocado no tempo
	float n = (hash(UV * vec2(1280.0, 720.0) + fract(TIME) * 137.0) - 0.5) * grain_strength;

	vec3 col = vignette_color + vec3(n);
	float a = clamp(vig + abs(n), 0.0, 0.96);
	COLOR = vec4(col, a);
}
