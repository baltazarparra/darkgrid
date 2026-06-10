extends GutTest

var _prev_phase: int

func before_each():
	_prev_phase = GameState.active_phase

func after_each():
	GameState.active_phase = _prev_phase

func _make_backdrop(phase: int) -> ArenaBackdrop:
	GameState.active_phase = phase
	var backdrop := ArenaBackdrop.new()
	add_child_autofree(backdrop)
	return backdrop

func test_forest_phase_builds_sky_and_floor_layers() -> void:
	var backdrop := _make_backdrop(1)
	assert_eq(backdrop._layers.size(), 2, "céu + chão; parede de igreja só na P5")
	assert_eq(backdrop._layers[0].shake_follow, ArenaBackdrop.SHAKE_FOLLOW_SKY)
	assert_eq(backdrop._layers[1].shake_follow, ArenaBackdrop.SHAKE_FOLLOW_FLOOR)

func test_church_phase_adds_wall_layer() -> void:
	var backdrop := _make_backdrop(5)
	assert_eq(backdrop._layers.size(), 3)
	assert_eq(backdrop._layers[2].shake_follow, ArenaBackdrop.SHAKE_FOLLOW_MID)

func test_layers_draw_before_treelines() -> void:
	# Ordem de filhos = ordem de desenho: copas das treelines por cima do céu.
	var backdrop := _make_backdrop(1)
	var last_layer_idx: int = backdrop._layers[-1].get_index()
	for child in backdrop.get_children():
		if child is TitleTreeline:
			assert_gt(child.get_index(), last_layer_idx,
				"treeline deve desenhar depois das camadas estáticas")

func test_shake_parallax_moves_layers_without_redraw() -> void:
	var backdrop := _make_backdrop(1)
	var cam := Camera2D.new()
	add_child_autofree(cam)
	cam.make_current()
	cam.offset = Vector2(10.0, -4.0)
	backdrop._process(0.016)
	assert_eq(backdrop._layers[0].position, Vector2(10.0, -4.0) * ArenaBackdrop.SHAKE_FOLLOW_SKY)
	assert_eq(backdrop._layers[1].position, Vector2(10.0, -4.0) * ArenaBackdrop.SHAKE_FOLLOW_FLOOR)

func test_shake_settles_back_to_origin() -> void:
	var backdrop := _make_backdrop(1)
	var cam := Camera2D.new()
	add_child_autofree(cam)
	cam.make_current()
	cam.offset = Vector2(8.0, 8.0)
	backdrop._process(0.016)
	cam.offset = Vector2.ZERO
	backdrop._process(0.016)
	for layer in backdrop._layers:
		assert_eq(layer.position, Vector2.ZERO)
