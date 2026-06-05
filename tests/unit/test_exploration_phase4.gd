extends GutTest

# Integração da Fase 4 procedural (manager único, phase=4): a Casa em chamas,
# boss Saci, sem tile de saída (progride ao derrotar o Saci → ENDING).

func after_each() -> void:
	GameState.player_map_pos = Vector2i(-1, -1)
	GameState.defeated_enemy_ids.clear()

func test_phase4_loads_with_saci_and_no_exit() -> void:
	GameState.start_run()
	GameState.player_map_pos = Vector2i(-1, -1)
	var expected := MapGenerator.new().generate(MapConfig.for_phase(4), GameState.map_seed_for_phase(4))

	var scene := preload("res://scenes/exploration/exploration_phase4.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame

	assert_eq(scene.get_node("Enemies").get_child_count(), MapConfig.for_phase(4).enemy_count,
		"spawna os inimigos do mapa gerado (6)")
	assert_eq(expected.boss().get("boss_type", ""), "saci", "boss da Fase 4 é o Saci")
	assert_false(MapConfig.for_phase(4).has_exit, "Fase 4 não tem saída (derrota o Saci)")
	assert_eq(expected.exit_pos, Vector2i(-1, -1), "Fase 4 não expõe exit_pos")
