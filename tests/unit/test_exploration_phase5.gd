extends GutTest

# Integração da Fase FINAL (manager único, phase=5): A Igreja na Mata. Os
# "monstros" são os 4 chefes convertidos; o Jesuíta no altar; sem tile de saída
# (progride ao derrotá-lo → ENDING); diálogo de abertura trava o movimento.

func after_each() -> void:
	GameState.player_map_pos = Vector2i(-1, -1)
	GameState.defeated_enemy_ids.clear()
	GameState.active_combat_keeps_own_hp = false

func _load_phase5() -> Node:
	GameState.start_run()
	GameState.player_map_pos = Vector2i(-1, -1)
	var scene := preload("res://scenes/exploration/exploration_phase5.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	return scene

func test_phase5_loads_with_jesuita_and_no_exit() -> void:
	var scene := await _load_phase5()
	assert_eq(scene.get_node("Enemies").get_child_count(), MapConfig.for_phase(5).enemy_count,
		"spawna os 5 inimigos do mapa gerado")
	var expected := MapGenerator.new().generate(MapConfig.for_phase(5), GameState.map_seed_for_phase(5))
	assert_eq(expected.boss().get("boss_type", ""), "jesuita", "boss da Fase 5 é o Jesuíta")
	assert_false(MapConfig.for_phase(5).has_exit, "Fase 5 não tem saída")
	assert_eq(expected.exit_pos, Vector2i(-1, -1), "Fase 5 não expõe exit_pos")

func test_phase5_monsters_are_the_four_bosses() -> void:
	var scene := await _load_phase5()
	var types := {}
	var bosses := 0
	for child in scene.get_node("Enemies").get_children():
		if child.is_boss:
			bosses += 1
			continue
		types[child.enemy_type] = true
	assert_eq(bosses, 1, "exatamente 1 boss (Jesuíta) na Fase 5")
	for t: String in ["mula", "boitata", "curupira", "saci"]:
		assert_true(types.has(t), "monstro %s presente na igreja" % t)
	assert_eq(types.size(), 4, "os 4 monstros são exatamente os 4 chefes")

func test_phase5_intro_dialogue_locks_then_unlocks() -> void:
	var scene := await _load_phase5()
	assert_true(scene._locked, "movimento travado durante a fala de abertura")
	var dlg := _find_dialogue(scene)
	assert_not_null(dlg, "DialogueScreen de abertura instanciado")
	# Avança as 2 falas → libera o movimento.
	dlg._ready_for_input = true
	dlg.advance()
	dlg._ready_for_input = true
	dlg.advance()
	await get_tree().process_frame
	assert_false(scene._locked, "movimento liberado após a fala de abertura")

func test_phase5_intro_skipped_on_combat_return() -> void:
	# Voltando do combate (player_map_pos != -1), a fala de abertura NÃO se repete.
	GameState.start_run()
	GameState.player_map_pos = Vector2i(3, 3)
	var scene := preload("res://scenes/exploration/exploration_phase5.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	assert_null(_find_dialogue(scene), "sem diálogo de abertura na volta do combate")
	assert_false(scene._locked, "movimento livre na volta do combate")

func _find_dialogue(scene: Node) -> Node:
	for child in scene.get_children():
		if child is DialogueScreen:
			return child
	return null
