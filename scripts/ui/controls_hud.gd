class_name ControlsHud
extends CanvasLayer

# D-pad de toque que espelha as setas do teclado. Na exploração/HUB usa o pad
# flutuante padrão MOBA/AAA mobile; na arena volta para a cruz antiga de setas
# explícitas, mais legível para comandos de timing. Cada press/release dirige os
# DOIS consumidores de input do jogo:
#   - Input.action_press/release  -> estado polado por caipora.gd (movimento)
#   - Input.parse_input_event     -> evento recebido por timing_system._input (combate)

# ─── Constants ─────────────────────────────────────
# Raio do pad flutuante como fração do lado menor do viewport.
const PAD_RADIUS_FRACTION: float = 0.17
const PAD_RADIUS_MIN: float = 56.0
const PAD_RADIUS_MAX: float = 120.0
const PAD_PORTRAIT_SCALE: float = 1.15
const REST_MARGIN_FRACTION: float = 0.55

# Faixa do topo excluída da ativação do pad flutuante: ali vivem HUD e áudio.
const TOP_EXCLUSION_FRACTION: float = 0.18

# Visual antigo do combate: cruz fixa de setas, responsiva e fora das bolhas.
const COMBAT_KEY_FRACTION: float = 0.13
const COMBAT_KEY_MIN: float = 56.0
const COMBAT_KEY_MAX: float = 96.0
const COMBAT_PORTRAIT_SCALE: float = 1.2
const COMBAT_MAX_WIDTH_FRACTION: float = 0.58
const COMBAT_GAP_FRACTION: float = 0.10
const COMBAT_SIDE_MARGIN_FRACTION: float = 0.45
const COMBAT_BOTTOM_MARGIN_FRACTION: float = 0.55
const COMBAT_LANDSCAPE_CENTER_Y_FRACTION: float = 0.62
const COMBAT_LANDSCAPE_BOTTOM_MARGIN_FRACTION: float = 0.18
const COMBAT_PRESS_SCALE: float = 0.92
const COMBAT_PRESS_TWEEN_SECONDS: float = 0.045
const COMBAT_HAPTIC_MS: int = 10
const TOUCH_SAFE_MARGIN: float = 28.0

const MODE_EXPLORATION: int = 0
const MODE_COMBAT: int = 1

# Sentinelas de ponteiro: índices de toque reais são >= 0.
const NO_POINTER: int = -1
const MOUSE_POINTER_INDEX: int = -1000

const _BUILD_TAG: String = "dpad-float-combat-arrows-1"
const _GAMEPLAY_SCREEN_PREFIXES: Array = ["EXPLORATION", "ARENA", "HUB"]
const FloatingDpadScript := preload("res://scripts/ui/floating_dpad.gd")
const _ENTRIES: Array = [
	["ui_up", "↑"],
	["ui_left", "←"],
	["ui_down", "↓"],
	["ui_right", "→"],
]

# ─── State ─────────────────────────────────────────
var _root: Control = null
var _pad = null
var _keys: Array[BaseButton] = []
var _pointer_index: int = NO_POINTER
var _dpad_rect: Rect2 = Rect2()
var _active_screen_wants_dpad: bool = false
var _active_screen_is_arena: bool = false
var _button_mode: int = -1
var _touch_detected: bool = false


# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	layer = 20
	print("[caipora] build ", _BUILD_TAG)
	SignalBus.screen_changed.connect(_on_screen_changed)


func _on_screen_changed(screen: SignalBus.Screen) -> void:
	_active_screen_wants_dpad = _is_gameplay_screen(screen)
	_active_screen_is_arena = _is_arena_screen(screen)
	_refresh()


func _is_gameplay_screen(screen: SignalBus.Screen) -> bool:
	var name: String = SignalBus.Screen.keys()[screen]
	for prefix: String in _GAMEPLAY_SCREEN_PREFIXES:
		if name.begins_with(prefix):
			return true
	return false


func _is_arena_screen(screen: SignalBus.Screen) -> bool:
	return SignalBus.Screen.keys()[screen].begins_with("ARENA")


func _input(event: InputEvent) -> void:
	if _touch_detected:
		return
	if not _active_screen_wants_dpad:
		return
	if MetaProgression.get_touch_controls_mode() == "never":
		return
	if event is InputEventScreenTouch and event.pressed:
		_touch_detected = true
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if _button_mode != MODE_EXPLORATION:
		return
	if _root == null or not _root.visible or _pad == null:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_try_begin(event.index, event.position)
		elif event.index == _pointer_index:
			_end_gesture()
	elif event is InputEventScreenDrag:
		if event.index == _pointer_index:
			_pad.drag_to(event.position)
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_try_begin(MOUSE_POINTER_INDEX, event.position)
			elif _pointer_index == MOUSE_POINTER_INDEX:
				_end_gesture()
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		if _pointer_index == MOUSE_POINTER_INDEX:
			_pad.drag_to(event.position)


# ─── Public API ────────────────────────────────────
func get_dpad_screen_rect() -> Rect2:
	if _root == null or not _root.visible:
		return Rect2()
	if _button_mode == MODE_COMBAT:
		return _dpad_rect
	if _pad == null:
		return Rect2()
	return _pad.get_screen_rect()


# ─── Private helpers ───────────────────────────────
func _resolve_should_show() -> bool:
	if not _active_screen_wants_dpad:
		return false
	match MetaProgression.get_touch_controls_mode():
		"never":
			return false
		"always":
			return true
		_:
			if not _touch_detected and _is_touch_device():
				_touch_detected = true
			return _touch_detected


func _refresh() -> void:
	if _resolve_should_show():
		_init_controls()
		_show()
	else:
		_hide()


func _show() -> void:
	if _root != null:
		_sync_control_mode()
		_layout_controls()
		_root.visible = true


func _hide() -> void:
	_end_gesture()
	_release_all_actions()
	if _root != null:
		_root.visible = false
	_dpad_rect = Rect2()


func _is_touch_device() -> bool:
	if OS.has_feature("web"):
		var result: Variant = JavaScriptBridge.eval(
			"navigator.maxTouchPoints > 0 || 'ontouchstart' in window", true
		)
		if result != null and result != false and result != 0:
			return true

		var ua: Variant = JavaScriptBridge.eval("navigator.userAgent", true)
		if ua is String:
			var ua_str: String = ua.to_lower()
			if ua_str.contains("iphone") or ua_str.contains("ipad") or ua_str.contains("ipod") or ua_str.contains("android"):
				return true

		var vp_w: Variant = JavaScriptBridge.eval("window.innerWidth", true)
		if vp_w is int or vp_w is float:
			if int(vp_w) < 1024:
				return true

		return false

	return DisplayServer.is_touchscreen_available()


func _init_controls() -> void:
	if _root != null:
		return

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_sync_control_mode()
	_layout_controls()
	get_viewport().size_changed.connect(_layout_controls)


func _sync_control_mode() -> void:
	if _root == null:
		return
	var desired_mode := MODE_COMBAT if _active_screen_is_arena else MODE_EXPLORATION
	if desired_mode == _button_mode:
		return

	_end_gesture()
	_release_all_actions()
	for child in _root.get_children():
		_root.remove_child(child)
		child.queue_free()
	_pad = null
	_keys.clear()
	_dpad_rect = Rect2()
	_button_mode = desired_mode

	if _button_mode == MODE_COMBAT:
		_build_combat_buttons()
	else:
		_build_floating_pad()


func _build_floating_pad() -> void:
	_pad = FloatingDpadScript.new()
	_pad.direction_pressed.connect(_on_pressed)
	_pad.direction_released.connect(_on_released)
	_root.add_child(_pad)


func _build_combat_buttons() -> void:
	for entry in _ENTRIES:
		var action: String = entry[0]
		var btn := _make_combat_button(entry[1])
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.button_down.connect(_on_pressed.bind(action))
		btn.button_up.connect(_on_released.bind(action))
		_root.add_child(btn)
		_keys.append(btn)


func _make_combat_button(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.add_theme_font_size_override("font_size", Constants.FONT_MD)
	btn.add_theme_color_override("font_color", Constants.COLOR_TEXT)
	btn.add_theme_color_override("font_pressed_color", Constants.COLOR_AMBER)
	btn.add_theme_stylebox_override("normal", _combat_style(false))
	btn.add_theme_stylebox_override("hover", _combat_style(false))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", _combat_style(true))
	return btn


func _combat_style(pressed: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.10, 0.98 if pressed else 0.90)
	style.border_color = Constants.COLOR_AMBER if pressed else Color(0.50, 0.44, 0.62, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style


func _layout_controls() -> void:
	if _root == null:
		return
	if _button_mode == MODE_COMBAT:
		_layout_combat_buttons()
	else:
		_layout_pad()


func _layout_pad() -> void:
	if _pad == null:
		return

	var vp := get_viewport().get_visible_rect().size
	var radius: float = clampf(minf(vp.x, vp.y) * PAD_RADIUS_FRACTION, PAD_RADIUS_MIN, PAD_RADIUS_MAX)
	if _touch_detected and Constants.is_portrait(vp):
		radius *= PAD_PORTRAIT_SCALE

	var safe: Vector2 = _get_safe_margins()
	var margin: float = radius * REST_MARGIN_FRACTION
	var rest := Vector2(
		vp.x - safe.x - margin - radius,
		vp.y - safe.y - margin - radius
	)
	var clamp_min := Vector2(radius, vp.y * TOP_EXCLUSION_FRACTION)
	var clamp_max := Vector2(vp.x - radius, vp.y - safe.y - radius)
	var clamp_rect := Rect2(clamp_min, (clamp_max - clamp_min).max(Vector2.ZERO))

	_pad.configure(radius, rest, clamp_rect)


func _layout_combat_buttons() -> void:
	if _keys.is_empty():
		return

	var vp := get_viewport().get_visible_rect().size
	var key: float = clampf(minf(vp.x, vp.y) * COMBAT_KEY_FRACTION, COMBAT_KEY_MIN, COMBAT_KEY_MAX)
	if _touch_detected and Constants.is_portrait(vp):
		key *= COMBAT_PORTRAIT_SCALE

	var gap: float = key * COMBAT_GAP_FRACTION
	var safe: Vector2 = _get_safe_margins()
	var side_margin: float = maxf(key * COMBAT_SIDE_MARGIN_FRACTION, safe.x)
	var cluster_w: float = key * 3.0 + gap * 2.0
	var cluster_h: float = key * 2.0 + gap
	var max_cluster_w: float = vp.x * COMBAT_MAX_WIDTH_FRACTION - side_margin
	if cluster_w > max_cluster_w and max_cluster_w > 0.0:
		var shrink: float = max_cluster_w / cluster_w
		key *= shrink
		gap *= shrink
		cluster_w = key * 3.0 + gap * 2.0
		cluster_h = key * 2.0 + gap

	var cluster: Vector2 = Vector2(cluster_w, cluster_h)
	var origin: Vector2 = _combat_origin_for_metrics(vp, safe, cluster, key)
	_dpad_rect = Rect2(origin, cluster)

	var cx: float = origin.x + key + gap
	var y_top: float = origin.y
	var y_bot: float = origin.y + key + gap
	var positions: Array[Vector2] = [
		Vector2(cx, y_top),
		Vector2(origin.x, y_bot),
		Vector2(cx, y_bot),
		Vector2(origin.x + key * 2.0 + gap * 2.0, y_bot),
	]

	for i in _keys.size():
		var btn := _keys[i]
		btn.position = positions[i]
		btn.size = Vector2(key, key)
		btn.pivot_offset = btn.size * 0.5


func _combat_origin_for_metrics(vp: Vector2, safe: Vector2, cluster: Vector2, key: float) -> Vector2:
	var side_margin: float = maxf(key * COMBAT_SIDE_MARGIN_FRACTION, safe.x)
	if Constants.is_portrait(vp):
		var bottom_margin: float = maxf(key * COMBAT_BOTTOM_MARGIN_FRACTION, safe.y)
		return Vector2(
			vp.x - side_margin - cluster.x,
			vp.y - bottom_margin - cluster.y
		)

	var target_y: float = vp.y * COMBAT_LANDSCAPE_CENTER_Y_FRACTION - cluster.y * 0.5
	var min_y: float = vp.y * TOP_EXCLUSION_FRACTION
	var max_y: float = vp.y - safe.y - key * COMBAT_LANDSCAPE_BOTTOM_MARGIN_FRACTION - cluster.y
	max_y = maxf(min_y, max_y)
	return Vector2(
		vp.x - side_margin - cluster.x,
		clampf(target_y, min_y, max_y)
	)


func _try_begin(index: int, point: Vector2) -> void:
	if _pointer_index != NO_POINTER:
		return
	if GameState.is_paused:
		return
	if not _is_in_activation_zone(point):
		return
	_pointer_index = index
	_pad.begin_touch(point)
	get_viewport().set_input_as_handled()


func _end_gesture() -> void:
	if _pointer_index == NO_POINTER:
		return
	_pointer_index = NO_POINTER
	if _pad != null:
		_pad.end_touch()


func _is_in_activation_zone(point: Vector2) -> bool:
	var vp := get_viewport().get_visible_rect().size
	return point.y >= vp.y * TOP_EXCLUSION_FRACTION


func _get_safe_margins() -> Vector2:
	var right: float = 0.0
	var bottom: float = 0.0

	if OS.has_feature("web"):
		var eval_right: Variant = JavaScriptBridge.eval(
			"parseInt(getComputedStyle(document.documentElement).getPropertyValue('--sari') || 0)", true
		)
		var eval_bottom: Variant = JavaScriptBridge.eval(
			"parseInt(getComputedStyle(document.documentElement).getPropertyValue('--sab') || 0)", true
		)
		if (eval_right == null or eval_right == 0) and (eval_bottom == null or eval_bottom == 0):
			var sar: Variant = JavaScriptBridge.eval(
				"(function(){var d=document.createElement('div');d.style.paddingRight='env(safe-area-inset-right)';d.style.paddingBottom='env(safe-area-inset-bottom)';d.style.position='absolute';document.body.appendChild(d);var s=getComputedStyle(d);var r=parseFloat(s.paddingRight)||0;var b=parseFloat(s.paddingBottom)||0;document.body.removeChild(d);return r+','+b;})()", true
			)
			if sar is String:
				var parts: PackedStringArray = sar.split(",")
				if parts.size() == 2:
					right = float(parts[0])
					bottom = float(parts[1])
		else:
			if eval_right is int or eval_right is float:
				right = float(eval_right)
			if eval_bottom is int or eval_bottom is float:
				bottom = float(eval_bottom)
	else:
		var safe_rect: Rect2 = DisplayServer.get_display_safe_area()
		var screen_size: Vector2i = DisplayServer.screen_get_size()
		right = float(screen_size.x - safe_rect.end.x)
		bottom = float(screen_size.y - safe_rect.end.y)

	if _is_touch_device():
		right = maxf(right, TOUCH_SAFE_MARGIN)
		bottom = maxf(bottom, TOUCH_SAFE_MARGIN)

	return Vector2(right, bottom)


func _on_pressed(action: String) -> void:
	_apply_combat_button_feedback(action, true)
	_pulse_combat_haptic()
	Input.action_press(action)
	_feed_event(action, true)


func _on_released(action: String) -> void:
	_apply_combat_button_feedback(action, false)
	Input.action_release(action)
	_feed_event(action, false)


func _release_all_actions() -> void:
	for entry in _ENTRIES:
		Input.action_release(entry[0])
	for btn in _keys:
		btn.scale = Vector2.ONE


func _feed_event(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)


func _apply_combat_button_feedback(action: String, pressed: bool) -> void:
	if _button_mode != MODE_COMBAT:
		return
	var index := _action_index(action)
	if index < 0 or index >= _keys.size():
		return
	var btn := _keys[index]
	var target := Vector2.ONE * (COMBAT_PRESS_SCALE if pressed else 1.0)
	var tween := btn.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", target, COMBAT_PRESS_TWEEN_SECONDS)


func _pulse_combat_haptic() -> void:
	if _button_mode != MODE_COMBAT:
		return
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval(
		"if (navigator.vibrate) navigator.vibrate(%d);" % COMBAT_HAPTIC_MS,
		false
	)


func _action_index(action: String) -> int:
	for i in _ENTRIES.size():
		if _ENTRIES[i][0] == action:
			return i
	return -1
