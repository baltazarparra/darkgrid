extends GutTest

# Trava o contrato que o D-pad de toque (ControlsHud) usa para dirigir o jogo:
#   - a action injetada via InputEventAction casa com o que TimingSystem._input espera
#   - o estado polado por Caipora._get_cardinal_input reflete Input.action_press/release
# Determinístico (chama _input / _get_cardinal_input direto), sem depender de input real.

var _timing: TimingSystem
var _caipora: Caipora

func before_each():
	_timing = TimingSystem.new()
	add_child_autofree(_timing)

	_caipora = preload("res://scenes/exploration/caipora.tscn").instantiate()
	add_child_autofree(_caipora)

func after_each():
	# Garante que nenhuma action fique "presa" entre os testes.
	Input.action_release("ui_right")

func test_injected_action_triggers_timing():
	var result: Array = [TimingSystem.TimingResult.MISS]
	_timing.timing_result.connect(func(r): result[0] = r)
	_timing.open_window(1.0, 0.35, 0.65, false, 0.0, 0.0, "ui_up")
	_timing._window_progress = 0.5

	var ev := InputEventAction.new()
	ev.action = "ui_up"
	ev.pressed = true
	_timing._input(ev)

	assert_eq(result[0], TimingSystem.TimingResult.PERFECT)

func test_action_press_drives_movement_polling():
	Input.action_press("ui_right")
	assert_eq(_caipora._get_cardinal_input(), Vector2.RIGHT)
	Input.action_release("ui_right")
	assert_eq(_caipora._get_cardinal_input(), Vector2.ZERO)
