extends GutTest

var _hud: ControlsHud = null
var _previous_touch_mode: String = "auto"

func before_each() -> void:
	_previous_touch_mode = MetaProgression.touch_controls_mode
	MetaProgression.touch_controls_mode = "always"
	_hud = ControlsHud.new()
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
	var rect := _hud.get_dpad_screen_rect()
	assert_eq(rect, Rect2(), "D-pad rect deve ser vazio quando não inicializado")

func test_get_dpad_screen_rect_returns_empty_after_queue_free() -> void:
	_hud.free()
	_hud = ControlsHud.new()
	var rect := _hud.get_dpad_screen_rect()
	assert_eq(rect, Rect2(), "D-pad rect deve ser vazio em instância nova")

func test_feed_event_creates_input_event_action() -> void:
	# _feed_event é privado; testamos indiretamente via _on_pressed/_on_released.
	# Como não inicializamos controles, chamamos os handlers diretamente.
	_hud._on_pressed("ui_up")
	assert_true(Input.is_action_pressed("ui_up"), "Action ui_up deve estar pressionada")

	_hud._on_released("ui_up")
	assert_false(Input.is_action_pressed("ui_up"), "Action ui_up deve estar solta")

func test_exploration_keeps_texture_dpad() -> void:
	_hud._on_screen_changed(SignalBus.Screen.EXPLORATION)
	assert_eq(_hud._button_mode, _hud.MODE_EXPLORATION, "exploração usa o D-pad atual")
	assert_true(_hud._keys[0] is TextureButton, "exploração mantém botões por textura")

func test_arena_uses_legacy_arrow_dpad() -> void:
	_hud._on_screen_changed(SignalBus.Screen.ARENA)
	assert_eq(_hud._button_mode, _hud.MODE_COMBAT, "arena usa o D-pad antigo")
	assert_true(_hud._keys[0] is Button, "combate usa botões de texto com setas")
	assert_eq((_hud._keys[0] as Button).text, "↑", "primeiro botão é a seta para cima")
	assert_gt(_hud.get_dpad_screen_rect().size.x, 0.0, "arena informa retângulo ocupado")

func test_all_arena_phase_screens_use_legacy_arrow_dpad() -> void:
	_hud._on_screen_changed(SignalBus.Screen.ARENA_PHASE5)
	assert_eq(_hud._button_mode, _hud.MODE_COMBAT, "ARENA_PHASE* também usa setas")
