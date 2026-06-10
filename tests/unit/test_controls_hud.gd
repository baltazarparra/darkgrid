extends GutTest

const ControlsHudScript := preload("res://scripts/ui/controls_hud.gd")

var _hud = null
var _previous_touch_mode: String = "auto"

func before_each() -> void:
	_previous_touch_mode = MetaProgression.touch_controls_mode
	MetaProgression.touch_controls_mode = "always"
	_hud = ControlsHudScript.new()
	add_child(_hud)

func after_each() -> void:
	MetaProgression.touch_controls_mode = _previous_touch_mode
	if is_instance_valid(_hud):
		_hud.free()
	_hud = null
	for action in ["ui_right", "ui_left", "ui_up", "ui_down"]:
		Input.action_release(action)

func test_get_dpad_screen_rect_returns_empty_when_not_initialized() -> void:
	# Antes de _init_controls(), o retângulo deve ser vazio.
	var rect: Rect2 = _hud.get_dpad_screen_rect()
	assert_eq(rect, Rect2(), "D-pad rect deve ser vazio quando não inicializado")

func test_get_dpad_screen_rect_returns_empty_after_queue_free() -> void:
	_hud.free()
	_hud = ControlsHudScript.new()
	var rect: Rect2 = _hud.get_dpad_screen_rect()
	assert_eq(rect, Rect2(), "D-pad rect deve ser vazio em instância nova")

func test_feed_event_creates_input_event_action() -> void:
	# _feed_event é privado; testamos indiretamente via _on_pressed/_on_released.
	# Como não inicializamos controles, chamamos os handlers diretamente.
	_hud._on_pressed("ui_up")
	assert_true(Input.is_action_pressed("ui_up"), "Action ui_up deve estar pressionada")

	_hud._on_released("ui_up")
	assert_false(Input.is_action_pressed("ui_up"), "Action ui_up deve estar solta")

func test_exploration_keeps_floating_dpad() -> void:
	_hud._on_screen_changed(SignalBus.Screen.EXPLORATION)
	assert_eq(_hud._button_mode, _hud.MODE_EXPLORATION, "exploração usa o D-pad atual")
	assert_not_null(_hud._pad, "exploração usa o pad flutuante")
	assert_true(_hud._keys.is_empty(), "exploração não usa botões fixos")

func test_arena_uses_legacy_arrow_dpad() -> void:
	_hud._on_screen_changed(SignalBus.Screen.ARENA)
	assert_eq(_hud._button_mode, _hud.MODE_COMBAT, "arena usa o D-pad antigo")
	assert_true(_hud._keys[0] is Button, "combate usa botões de texto com setas")
	assert_eq((_hud._keys[0] as Button).text, "↑", "primeiro botão é a seta para cima")
	assert_gt(_hud.get_dpad_screen_rect().size.x, 0.0, "arena informa retângulo ocupado")

func test_arena_dpad_sits_in_right_thumb_zone() -> void:
	_hud._on_screen_changed(SignalBus.Screen.ARENA)
	var rect: Rect2 = _hud.get_dpad_screen_rect()
	var vp: Vector2 = _hud.get_viewport().get_visible_rect().size
	var center: Vector2 = rect.position + rect.size * 0.5

	assert_gt(center.x, vp.x * 0.5, "D-pad de combate fica no lado direito")
	assert_gt(center.y, vp.y * 0.5, "D-pad de combate fica na metade inferior")
	assert_lt(center.y, vp.y * 0.78, "D-pad de combate não afunda no rodapé em paisagem")
	assert_lte(rect.end.x, vp.x, "D-pad de combate respeita a borda direita")
	assert_lte(rect.end.y, vp.y, "D-pad de combate respeita a borda inferior")

func test_landscape_arena_dpad_anchors_to_right_thumb_band() -> void:
	var vp: Vector2 = Vector2(852.0, 393.0)
	var key: float = 64.0
	var gap: float = key * _hud.COMBAT_GAP_FRACTION
	var cluster: Vector2 = Vector2(key * 3.0 + gap * 2.0, key * 2.0 + gap)
	var rect: Rect2 = Rect2(
		_hud._combat_origin_for_metrics(vp, Vector2(28.0, 28.0), cluster, key),
		cluster
	)
	var center: Vector2 = rect.position + rect.size * 0.5

	assert_gt(center.x, vp.x * 0.80, "paisagem ancora o D-pad na faixa do polegar direito")
	assert_gt(center.y, vp.y * 0.50, "paisagem mantém o D-pad abaixo do centro")
	assert_lt(center.y, vp.y * 0.72, "paisagem mantém o D-pad fora do canto inferior")
	assert_gt(vp.y - rect.end.y, key * 0.15, "paisagem mantém folga inferior para segurar o aparelho")

func test_arena_dpad_keeps_thumb_sized_targets() -> void:
	_hud._on_screen_changed(SignalBus.Screen.ARENA)
	for key in _hud._keys:
		assert_gte(key.size.x, _hud.COMBAT_KEY_MIN, "alvo de toque mantém largura confortável")
		assert_gte(key.size.y, _hud.COMBAT_KEY_MIN, "alvo de toque mantém altura confortável")

func test_all_arena_phase_screens_use_legacy_arrow_dpad() -> void:
	_hud._on_screen_changed(SignalBus.Screen.ARENA_PHASE5)
	assert_eq(_hud._button_mode, _hud.MODE_COMBAT, "ARENA_PHASE* também usa setas")
