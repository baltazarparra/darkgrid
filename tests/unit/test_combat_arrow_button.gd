extends GutTest

# Trava o contrato do CombatArrowButton (D-pad de combate): hit-test em gajo de 90°
# com zona morta central, orientação derivada da action e reset do feedback visual.

const CombatArrowButtonScript := preload("res://scripts/ui/combat_arrow_button.gd")

const SIDE: float = 240.0
const DEAD: float = 12.0

var _btn: CombatArrowButton = null

func before_each() -> void:
	_btn = CombatArrowButtonScript.new()
	add_child_autofree(_btn)
	_btn.size = Vector2(SIDE, SIDE)
	_btn.configure(Rect2(90.0, 10.0, 60.0, 60.0), Vector2(SIDE, SIDE) * 0.5, DEAD)

func after_each() -> void:
	_btn = null

func test_action_sets_orientation() -> void:
	var expected: Dictionary = {"ui_up": 0, "ui_right": 1, "ui_down": 2, "ui_left": 3}
	for action: String in expected:
		_btn.action = action
		assert_eq(_btn._orientation, expected[action], "%s orienta o glifo" % action)

func test_wedge_accepts_own_quadrant_only() -> void:
	var center := Vector2(SIDE, SIDE) * 0.5
	var probes: Dictionary = {
		"ui_up": center + Vector2(0.0, -80.0),
		"ui_right": center + Vector2(80.0, 0.0),
		"ui_down": center + Vector2(0.0, 80.0),
		"ui_left": center + Vector2(-80.0, 0.0),
	}
	for owner: String in probes:
		_btn.action = owner
		for probe_action: String in probes:
			var hit: bool = _btn._has_point(probes[probe_action])
			if probe_action == owner:
				assert_true(hit, "%s aceita o próprio gajo" % owner)
			else:
				assert_false(hit, "%s rejeita o gajo de %s" % [owner, probe_action])

func test_wedge_rejects_center_dead_zone() -> void:
	_btn.action = "ui_up"
	var center := Vector2(SIDE, SIDE) * 0.5
	assert_false(_btn._has_point(center), "centro morto não pressiona")
	assert_false(_btn._has_point(center + Vector2(0.0, -DEAD * 0.5)), "dentro do raio morto não pressiona")
	assert_true(_btn._has_point(center + Vector2(0.0, -DEAD * 2.0)), "logo após o raio morto pressiona")

func test_wedge_rejects_points_outside_rect() -> void:
	_btn.action = "ui_up"
	assert_false(_btn._has_point(Vector2(SIDE * 0.5, -10.0)), "fora do retângulo não pressiona")

func test_clear_feedback_resets_press_visual() -> void:
	_btn.action = "ui_down"
	_btn._on_visual_press()
	assert_eq(_btn._press_amount, 1.0, "press é instantâneo")
	assert_eq(_btn._ring_amount, 0.0, "anel de impacto dispara no press")
	_btn.clear_feedback()
	assert_eq(_btn._press_amount, 0.0, "clear_feedback zera o press")
	assert_eq(_btn._ring_amount, 1.0, "clear_feedback encerra o anel")

func test_set_window_open_true_sets_flag_and_tween() -> void:
	_btn.set_window_open(true)
	assert_true(_btn._window_open, "set_window_open(true) levanta a flag")
	assert_not_null(_btn._window_tween, "tween de janela criado")

func test_set_window_open_false_clears_flag() -> void:
	_btn.set_window_open(true)
	_btn.set_window_open(false)
	assert_false(_btn._window_open, "set_window_open(false) baixa a flag")

func test_flash_perfect_sets_amount_to_one() -> void:
	_btn.flash_perfect()
	assert_almost_eq(_btn._perfect_amount, 1.0, 0.001, "flash_perfect inicia em 1.0")
	assert_not_null(_btn._perfect_tween, "tween de perfeito criado")

func test_flash_miss_sets_amount_to_one() -> void:
	_btn.flash_miss()
	assert_almost_eq(_btn._miss_amount, 1.0, 0.001, "flash_miss inicia em 1.0")
	assert_not_null(_btn._miss_tween, "tween de miss criado")

func test_clear_feedback_resets_all_states() -> void:
	_btn.set_window_open(true)
	_btn.flash_perfect()
	_btn._on_visual_press()
	_btn.clear_feedback()
	assert_eq(_btn._press_amount, 0.0, "clear zera press")
	assert_eq(_btn._ring_amount, 1.0, "clear restaura anel")
	assert_eq(_btn._window_amount, 0.0, "clear zera window")
	assert_eq(_btn._perfect_amount, 0.0, "clear zera perfect")
	assert_eq(_btn._miss_amount, 0.0, "clear zera miss")
	assert_false(_btn._window_open, "clear baixa flag de janela")
