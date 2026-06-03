class_name EndingScreen
extends CanvasLayer

## Tela de encerramento do jogo. Sequência cinematográfica após derrotar o Curupira.
## Sem input durante a animação. Botão "Menu Principal" surge ao final.

var _input_blocked: bool = true
var _silhouette: CaiporaSilhouette

func _ready() -> void:
	layer = 20
	_run_sequence()

func _run_sequence() -> void:
	var overlay := ColorRect.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var forest_bg := _build_forest_bg()
	add_child(forest_bg)
	forest_bg.modulate.a = 0.0

	var label1 := _make_label("a floresta vive...", 0.0)
	var label2 := _make_label("por enquanto", 0.0)
	label2.position.y += 56
	add_child(label1)
	add_child(label2)

	_silhouette = CaiporaSilhouette.new()
	_silhouette.modulate.a = 0.0
	add_child(_silhouette)

	var menu_btn := _make_menu_button()
	add_child(menu_btn)

	var t := create_tween().set_trans(Tween.TRANS_SINE)

	# 1. Fade para preto
	t.tween_property(overlay, "color", Color(0, 0, 0, 1.0), 0.5)
	# 2. Texto 1 surge
	t.tween_property(label1, "modulate:a", 1.0, 1.2)
	t.tween_interval(1.5)
	# 3. Texto 2 surge
	t.tween_property(label2, "modulate:a", 1.0, 0.8)
	t.tween_interval(2.0)
	# 4. Texto some, floresta aparece
	t.tween_property(label1, "modulate:a", 0.0, 0.6)
	t.tween_property(label2, "modulate:a", 0.0, 0.6)
	t.tween_property(overlay, "color", Color(0, 0, 0, 0.0), 0.8)
	t.tween_property(forest_bg, "modulate:a", 1.0, 0.8)
	# 5. Silhueta anda
	t.tween_property(_silhouette, "modulate:a", 1.0, 1.0)
	t.tween_property(_silhouette, "position:x", 900.0, 8.0).set_trans(Tween.TRANS_LINEAR)
	# 6. Fade final
	t.tween_property(overlay, "color", Color(0, 0, 0, 1.0), 1.5)
	# 7. Botão aparece
	t.tween_callback(func():
		_input_blocked = false
		var btn_tween := create_tween()
		btn_tween.tween_property(menu_btn, "modulate:a", 1.0, 0.8)
	)

func _make_label(text: String, initial_alpha: float) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", Constants.FONT_LG)
	label.add_theme_color_override("font_color", Constants.COLOR_TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.anchor_top = 0.42
	label.anchor_bottom = 0.42
	label.modulate.a = initial_alpha
	return label

func _make_menu_button() -> Button:
	var btn := Button.new()
	btn.text = "Menu Principal"
	btn.add_theme_font_size_override("font_size", Constants.FONT_MD)
	btn.anchor_left = 0.35
	btn.anchor_right = 0.65
	btn.anchor_top = 0.88
	btn.anchor_bottom = 0.95
	btn.modulate.a = 0.0
	btn.pressed.connect(func(): GameState.change_screen(SignalBus.Screen.MAIN_MENU))
	return btn

func _build_forest_bg() -> ColorRect:
	var bg := ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Constants.COLOR_NIGHT
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bg

# ─── Silhueta da Caipora ───────────────────────────
class CaiporaSilhouette extends Node2D:
	func _ready() -> void:
		position = Vector2(-80, 300)

	func _draw() -> void:
		var col := Color(0.0, 0.0, 0.0, 1.0)
		# Corpo
		draw_rect(Rect2(-12, -64, 24, 48), col)
		# Cabeça
		draw_circle(Vector2(0, -72), 14, col)
		# Cabelo de fogo (silhueta)
		for i in 5:
			var ox := -14 + i * 7
			draw_rect(Rect2(ox, -92, 5, 22), col)
		# Braços
		draw_rect(Rect2(-26, -60, 12, 8), col)
		draw_rect(Rect2(14, -60, 12, 8), col)
		# Pernas
		draw_rect(Rect2(-10, -16, 8, 24), col)
		draw_rect(Rect2(2, -16, 8, 24), col)
