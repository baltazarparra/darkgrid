extends GutTest

func _make_life() -> AmbientLife:
	var life := AmbientLife.new()
	add_child_autofree(life)
	life.setup(Rect2(0, 0, 200, 200))
	return life

func _ant(pos: Vector2, vel: Vector2) -> Dictionary:
	return {
		"kind": AmbientLife.Kind.ANT,
		"pos": pos,
		"vel": vel,
		"heading": Vector2.RIGHT,
		"moving": true,
		"timer": 999.0,  # sem repath durante o teste
	}

func test_subtick_frame_does_not_step_insects() -> void:
	var life := _make_life()
	life._insects.clear()
	life._insects.append(_ant(Vector2(50, 50), Vector2(9, 0)))
	life._process(0.04)  # abaixo de TICK_INTERVAL (1/20s)
	assert_eq(life._insects[0].pos, Vector2(50, 50))

func test_tick_consumes_full_accumulated_step() -> void:
	# 20Hz não pode perder tempo: o passo usa o delta acumulado inteiro,
	# então a velocidade efetiva da formiga continua 9px/s.
	var life := _make_life()
	life._insects.clear()
	life._insects.append(_ant(Vector2(50, 50), Vector2(9, 0)))
	life._process(0.04)
	life._process(0.02)  # acumulado 0.06 >= 1/20
	assert_almost_eq(life._insects[0].pos.x, 50.0 + 9.0 * 0.06, 0.0001)

func test_forest_rays_are_static_polygons_with_shared_material() -> void:
	var amb := ForestAmbience.new()
	add_child_autofree(amb)
	amb.setup(Rect2(0, 0, 300, 300))
	assert_eq(amb._ray_nodes.size(), ForestAmbience.RAY_COUNT)
	for ray in amb._ray_nodes:
		assert_eq(ray.material, ForestAmbience.ADDITIVE_MATERIAL,
			"feixe deve usar o material aditivo compartilhado do projeto")
		assert_eq(ray.polygon.size(), 4)

func test_forest_ray_pulse_only_touches_alpha() -> void:
	var amb := ForestAmbience.new()
	add_child_autofree(amb)
	amb.setup(Rect2(0, 0, 300, 300))
	var poly_before: PackedVector2Array = amb._ray_nodes[0].polygon
	amb._process(0.5)
	assert_eq(amb._ray_nodes[0].polygon, poly_before, "pulso não pode re-tesselar o feixe")
	var alpha: float = amb._ray_nodes[0].self_modulate.a
	assert_between(alpha, 0.0,
		ForestAmbience.RAY_BASE_ALPHA + ForestAmbience.RAY_PULSE_ALPHA + 0.001)
