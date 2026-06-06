extends GutTest

## Apresentação de boss (estilo Mega Man) que precede o diálogo de toda boss fight.

const FRAMES: SpriteFrames = preload("res://assets/sprites/boitata_sprite_frames.tres")
const ACCENT := Color(1.0, 0.45, 0.05, 0.75)
const NAME_COLOR := Color(1.0, 0.42, 0.0, 1.0)

var _screen: BossIntroScreen

func before_each() -> void:
	_screen = preload("res://scenes/ui/boss_intro_screen.tscn").instantiate()
	add_child_autofree(_screen)

func test_start_sets_boss_name() -> void:
	_screen.start("BOITATÁ", FRAMES, ACCENT, NAME_COLOR)
	assert_eq(_screen._boss_name, "BOITATÁ")

func test_start_loads_boss_model() -> void:
	_screen.start("BOITATÁ", FRAMES, ACCENT, NAME_COLOR)
	assert_not_null(_screen._model, "modelo do boss deve ser montado")
	assert_eq(_screen._model.sprite_frames, FRAMES, "modelo usa as sprite frames do boss")
	assert_eq(_screen._model.animation, &"idle")

func test_start_emits_boss_intro_started() -> void:
	watch_signals(SignalBus)
	_screen.start("BOITATÁ", FRAMES, ACCENT, NAME_COLOR)
	assert_signal_emitted(SignalBus, "boss_intro_started")

func test_name_reveals_letter_by_letter() -> void:
	_screen.start("BOITATÁ", FRAMES, ACCENT, NAME_COLOR)
	# Revelação parcial mostra um prefixo do nome.
	_screen._set_name_chars(3)
	assert_eq(_screen._name_label.text, "BOI")
	_screen._set_name_chars("BOITATÁ".length())
	assert_eq(_screen._name_label.text, "BOITATÁ")

func test_finish_emits_boss_intro_finished() -> void:
	watch_signals(SignalBus)
	_screen.start("BOITATÁ", FRAMES, ACCENT, NAME_COLOR)
	_screen.finish()
	assert_signal_emitted(SignalBus, "boss_intro_finished")

func test_finish_is_idempotent() -> void:
	watch_signals(SignalBus)
	_screen.start("BOITATÁ", FRAMES, ACCENT, NAME_COLOR)
	_screen.finish()
	_screen.finish()
	# finish() guarda contra emissão dupla mesmo se chamado de novo.
	assert_signal_emit_count(SignalBus, "boss_intro_finished", 1)

# ─── Skip: qualquer tecla / toque / clique encerra a apresentação ───

func test_touch_is_skip_event() -> void:
	var ev := InputEventScreenTouch.new()
	ev.pressed = true
	assert_true(_screen._is_skip_event(ev), "toque deve pular a apresentação")

func test_touch_release_is_not_skip() -> void:
	var ev := InputEventScreenTouch.new()
	ev.pressed = false
	assert_false(_screen._is_skip_event(ev), "soltar o toque não pula")

func test_any_key_is_skip_event() -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_X
	ev.pressed = true
	assert_true(_screen._is_skip_event(ev), "qualquer tecla deve pular")

func test_key_echo_is_not_skip() -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_SPACE
	ev.pressed = true
	ev.echo = true
	assert_false(_screen._is_skip_event(ev), "auto-repeat (echo) não pula")

func test_mouse_click_is_skip_event() -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	assert_true(_screen._is_skip_event(ev), "clique deve pular")
