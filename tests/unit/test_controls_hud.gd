extends GutTest

var _hud: ControlsHud = null

func before_each() -> void:
	_hud = ControlsHud.new()
	add_child(_hud)

func after_each() -> void:
	if is_instance_valid(_hud):
		_hud.queue_free()
	_hud = null

func test_get_dpad_screen_rect_returns_empty_when_not_initialized() -> void:
	# Antes de _init_controls(), o retângulo deve ser vazio.
	var rect := _hud.get_dpad_screen_rect()
	assert_eq(rect, Rect2(), "D-pad rect deve ser vazio quando não inicializado")

func test_get_dpad_screen_rect_returns_empty_after_queue_free() -> void:
	_hud.queue_free()
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
