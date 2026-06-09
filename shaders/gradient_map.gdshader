shader_type canvas_item;

// Color grading por gradient map: luminância da tela → cor da LUT 256x1 da
// fase. Lê SCREEN_TEXTURE — custo real em gl_compatibility web; por isso fica
// atrás de flag (Constants.GRADING_*) e numa CanvasLayer ABAIXO do HUD (a UI
// não é graduada). Validar FPS em dispositivo antes de ligar no web.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform sampler2D grade_lut : filter_linear, repeat_disable;
uniform float mix_amount : hint_range(0.0, 1.0) = 0.75;

void fragment() {
	vec3 src = texture(screen_tex, SCREEN_UV).rgb;
	float lum = dot(src, vec3(0.299, 0.587, 0.114));
	vec3 graded = texture(grade_lut, vec2(lum, 0.5)).rgb;
	COLOR = vec4(mix(src, graded, mix_amount), 1.0);
}
