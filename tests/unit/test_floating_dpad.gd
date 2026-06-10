extends GutTest

# Trava o contrato do pad flutuante (padrão MOBA): resolução de direção cardinal com
# zona morta e histerese de eixo, follow da base além do raio, clamp do centro e os
# sinais press/release que o ControlsHud traduz na injeção dual de input.

const DEAD: float = 12.0
const RADIUS: float = 60.0

var _pad: FloatingDpad

func before_each() -> void:
	_pad = FloatingDpad.new()
	add_child_autofree(_pad)
	_pad.configure(RADIUS, Vector2(400.0, 400.0), Rect2(60.0, 60.0, 800.0, 800.0))

func test_rest_pose_applied_on_configure() -> void:
	assert_eq(_pad.position, Vector2(400.0, 400.0), "Sem toque ativo, o pad fica na pose de repouso")

func test_resolve_action_dead_zone_returns_empty() -> void:
	assert_eq(FloatingDpad.resolve_action(Vector2(6.0, 0.0), DEAD, ""), "")
	assert_eq(FloatingDpad.resolve_action(Vector2.ZERO, DEAD, "ui_right"), "")

func test_resolve_action_all_cardinals() -> void:
	assert_eq(FloatingDpad.resolve_action(Vector2(30.0, 0.0), DEAD, ""), "ui_right")
	assert_eq(FloatingDpad.resolve_action(Vector2(-30.0, 0.0), DEAD, ""), "ui_left")
	assert_eq(FloatingDpad.resolve_action(Vector2(0.0, -30.0), DEAD, ""), "ui_up")
	assert_eq(FloatingDpad.resolve_action(Vector2(0.0, 30.0), DEAD, ""), "ui_down")

func test_axis_hysteresis_keeps_current_axis_near_diagonal() -> void:
	# Com ui_right ativa, um arrasto a ~45° (22 > 20) ainda NÃO troca de eixo…
	assert_eq(FloatingDpad.resolve_action(Vector2(20.0, 22.0), DEAD, "ui_right"), "ui_right")
	# …mas quando o eixo vertical domina com folga (> bias de 1.25x), troca.
	assert_eq(FloatingDpad.resolve_action(Vector2(20.0, 30.0), DEAD, "ui_right"), "ui_down")

func test_same_axis_flips_immediately() -> void:
	# Wiggle ←→ sem levantar o dedo (sequência do Curupira): sinal inverte na hora.
	assert_eq(FloatingDpad.resolve_action(Vector2(-25.0, 0.0), DEAD, "ui_right"), "ui_left")

func test_drag_emits_press_and_release_signals() -> void:
	watch_signals(_pad)
	_pad.begin_touch(Vector2(300.0, 300.0))
	_pad.drag_to(Vector2(340.0, 300.0))
	assert_signal_emitted_with_parameters(_pad, "direction_pressed", ["ui_right"])
	_pad.end_touch()
	assert_signal_emitted_with_parameters(_pad, "direction_released", ["ui_right"])

func test_direction_change_releases_previous_action() -> void:
	watch_signals(_pad)
	_pad.begin_touch(Vector2(300.0, 300.0))
	_pad.drag_to(Vector2(340.0, 300.0))
	_pad.drag_to(Vector2(260.0, 300.0))
	assert_signal_emitted_with_parameters(_pad, "direction_released", ["ui_right"])
	assert_signal_emitted_with_parameters(_pad, "direction_pressed", ["ui_left"])

func test_release_inside_dead_zone_emits_nothing() -> void:
	watch_signals(_pad)
	_pad.begin_touch(Vector2(300.0, 300.0))
	_pad.drag_to(Vector2(304.0, 300.0))
	_pad.end_touch()
	assert_signal_not_emitted(_pad, "direction_pressed")
	assert_signal_not_emitted(_pad, "direction_released")

func test_follow_drifts_base_beyond_radius() -> void:
	_pad.begin_touch(Vector2(300.0, 300.0))
	_pad.drag_to(Vector2(400.0, 300.0))
	# Dedo a 100px do centro, raio 60 -> a base segue os 40px excedentes.
	assert_almost_eq(_pad.position.x, 340.0, 0.01)
	assert_almost_eq(_pad.position.y, 300.0, 0.01)

func test_begin_touch_clamps_center_to_allowed_rect() -> void:
	_pad.begin_touch(Vector2(10.0, 10.0))
	assert_eq(_pad.position, Vector2(60.0, 60.0), "Centro nunca vaza do retângulo permitido")

func test_screen_rect_tracks_pad_position() -> void:
	_pad.begin_touch(Vector2(300.0, 300.0))
	var rect := _pad.get_screen_rect()
	assert_eq(rect.position, Vector2(300.0 - RADIUS, 300.0 - RADIUS))
	assert_eq(rect.size, Vector2(RADIUS * 2.0, RADIUS * 2.0))
