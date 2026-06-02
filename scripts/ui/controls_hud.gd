class_name ControlsHud
extends CanvasLayer

# D-pad de toque que espelha as setas do teclado, para jogar em iPhone/iPad.
# As 4 setas controlam tudo: movimento na exploração e o timing no combate.
# Cada toque dirige os DOIS consumidores de input do jogo:
#   - Input.action_press/release  -> estado polado por caipora.gd (movimento)
#   - Input.parse_input_event     -> evento recebido por timing_system._input (combate)
# Aparece apenas em dispositivos com tela de toque; no desktop o teclado é o controle.

# ─── Constants ─────────────────────────────────────
# Tamanho como fração do lado menor do viewport (~15%, recomendação de ergonomia mobile),
# com piso bem acima dos 44pt da Apple HIG e teto para não estourar no iPad.
const KEY_FRACTION: float = 0.15
const KEY_MIN: float = 64.0
const KEY_MAX: float = 140.0

# ─── State ─────────────────────────────────────────
var _root: Control = null
var _dpad_rect: Rect2 = Rect2()

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	layer = 20

	# Só faz sentido em telas de toque. No desktop, o teclado controla.
	if not DisplayServer.is_touchscreen_available():
		return

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_rebuild()
	get_viewport().size_changed.connect(_rebuild)


# ─── Public API ────────────────────────────────────
func get_dpad_screen_rect() -> Rect2:
	# Vazio quando não há D-pad (desktop / sem touch) -> sem exclusão.
	return _dpad_rect if _root != null else Rect2()


# ─── Private helpers ───────────────────────────────
func _rebuild() -> void:
	if _root == null:
		return
	for child in _root.get_children():
		child.queue_free()

	var vp := get_viewport().get_visible_rect().size
	var key: float = clampf(minf(vp.x, vp.y) * KEY_FRACTION, KEY_MIN, KEY_MAX)
	var gap: float = key * 0.12
	var margin: float = key * 0.4

	# Cluster em cruz: 3 colunas x 2 linhas, com dead zone no centro.
	var cluster_w: float = key * 3.0 + gap * 2.0
	var cluster_h: float = key * 2.0 + gap

	# Ancorado ao canto inferior DIREITO (zona do polegar direito).
	var origin := Vector2(vp.x - margin - cluster_w, vp.y - margin - cluster_h)

	# Retângulo em coordenadas de tela ocupado pelo cluster — consultado pela arena
	# para impedir que bolhas de timing nasçam atrás do D-pad.
	_dpad_rect = Rect2(origin, Vector2(cluster_w, cluster_h))

	var cx: float = origin.x + key + gap          # coluna central
	var y_top: float = origin.y                    # linha de cima (↑)
	var y_bot: float = origin.y + key + gap        # linha de baixo (← ↓ →)

	_key("↑", "ui_up",    cx,                       y_top, key)
	_key("←", "ui_left",  origin.x,                 y_bot, key)
	_key("↓", "ui_down",  cx,                       y_bot, key)
	_key("→", "ui_right", origin.x + key * 2.0 + gap * 2.0, y_bot, key)


func _key(label: String, action: String, x: float, y: float, key: float) -> void:
	var btn := Button.new()
	btn.position = Vector2(x, y)
	btn.size = Vector2(key, key)
	btn.text = label
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.10, 0.88)
	style.border_color = Color(0.50, 0.44, 0.62, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)

	var style_hover := style.duplicate() as StyleBoxFlat
	style_hover.bg_color = Color(0.10, 0.07, 0.16, 0.92)

	var style_pressed := style.duplicate() as StyleBoxFlat
	style_pressed.bg_color = Color(0.22, 0.16, 0.32, 0.96)
	style_pressed.border_color = Color(0.78, 0.70, 0.92, 1.0)

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", style)
	btn.add_theme_font_size_override("font_size", int(key * 0.45))
	btn.add_theme_color_override("font_color", Color(0.86, 0.82, 0.94, 1.0))

	btn.button_down.connect(_on_pressed.bind(action))
	btn.button_up.connect(_on_released.bind(action))
	_root.add_child(btn)


func _on_pressed(action: String) -> void:
	Input.action_press(action)
	_feed_event(action, true)


func _on_released(action: String) -> void:
	Input.action_release(action)
	_feed_event(action, false)


func _feed_event(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)
