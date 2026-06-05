extends GutTest

# Integração da Fase 2 procedural (manager único, phase=2): floresta em chamas,
# boss Boitatá, progressão por tile de saída → Fase 3.

func after_each() -> void:
	GameState.player_map_pos = Vector2i(-1, -1)
	GameState.defeated_enemy_ids.clear()

func test_phase2_loads_with_boitata_and_exit() -> void:
	GameState.start_run()
	GameState.player_map_pos = Vector2i(-1, -1)
	var expected := MapGenerator.new().generate(MapConfig.for_phase(2), GameState.map_seed_for_phase(2))

	var scene := preload("res://scenes/exploration/exploration_phase2.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame

	assert_eq(scene.get_node("Enemies").get_child_count(), MapConfig.for_phase(2).enemy_count,
		"spawna os inimigos do mapa gerado (4)")
	assert_eq(expected.boss().get("boss_type", ""), "boitata", "boss da Fase 2 é o Boitatá")
	assert_true(MapConfig.for_phase(2).has_exit, "Fase 2 tem saída (→ Fase 3)")
	# Sem fog na Fase 2.
	for c in scene.get_children():
		assert_false(c is FogOfWar, "Fase 2 não tem fog of war")
