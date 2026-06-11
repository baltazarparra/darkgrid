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

func test_arena_uses_claw_arrow_dpad() -> void:
	_hud._on_screen_changed(SignalBus.Screen.ARENA)
	assert_eq(_hud._button_mode, _hud.MODE_COMBAT, "arena usa o D-pad fixo de combate")
	assert_eq(_hud._keys.size(), 4, "combate tem 4 direções")
	assert_true(_hud._keys[0] is CombatArrowButton, "combate usa garras-chevron desenhadas")
	assert_eq((_hud._keys[0] as CombatArrowButton).action, "ui_up", "primeiro botão é a direção para cima")
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
	var side: float = key * 3.0 + gap * 2.0
	var cluster: Vector2 = Vector2(side, side)
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
	var cluster: Rect2 = _hud.get_dpad_screen_rect()
	for key in _hud._keys:
		var btn := key as CombatArrowButton
		assert_gte(btn._plate_rect.size.x, _hud.COMBAT_KEY_MIN, "plate visível mantém largura confortável")
		assert_gte(btn._plate_rect.size.y, _hud.COMBAT_KEY_MIN, "plate visível mantém altura confortável")
		assert_gt(btn.size.x, cluster.size.x, "área de toque excede o cluster visível (margem extra)")
		assert_gt(btn.size.y, cluster.size.y, "área de toque excede o cluster visível (margem extra)")

func test_arena_dpad_routes_whole_cluster_by_wedge() -> void:
	# Toda a área do pad é clicável: cada quadrante (gajo) pertence à sua direção,
	# mesmo FORA da plate desenhada — área efetiva de toque muito maior que o visual.
	_hud._on_screen_changed(SignalBus.Screen.ARENA)
	var actions_hit: Dictionary = {}
	for key in _hud._keys:
		var btn := key as CombatArrowButton
		var center: Vector2 = btn._wedge_center
		var arm: Vector2 = Vector2.ZERO
		match btn.action:
			"ui_up": arm = Vector2(0.0, -1.0)
			"ui_down": arm = Vector2(0.0, 1.0)
			"ui_left": arm = Vector2(-1.0, 0.0)
			"ui_right": arm = Vector2(1.0, 0.0)
		var probe: Vector2 = center + arm * (btn.size.x * 0.42)
		assert_true(btn._has_point(probe), "%s aceita o próprio gajo" % btn.action)
		assert_false(btn._has_point(center), "%s rejeita a zona morta central" % btn.action)
		for other in _hud._keys:
			if other != key and (other as CombatArrowButton)._has_point(probe):
				fail_test("gajo de %s também aceito por %s" % [btn.action, (other as CombatArrowButton).action])
		actions_hit[btn.action] = true
	assert_eq(actions_hit.size(), 4, "as 4 direções têm gajo próprio")

func test_all_arena_phase_screens_use_legacy_arrow_dpad() -> void:
	_hud._on_screen_changed(SignalBus.Screen.ARENA_PHASE5)
	assert_eq(_hud._button_mode, _hud.MODE_COMBAT, "ARENA_PHASE* também usa setas")
