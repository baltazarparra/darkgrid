extends GutTest

# Integração da Fase 1 procedural: a cena de exploração consome o GeneratedMap
# (em vez do MAP_LAYOUT estático) e fia spawn/inimigos a partir dele.

func after_each() -> void:
	GameState.player_map_pos = Vector2i(-1, -1)
	GameState.defeated_enemy_ids.clear()

func test_phase1_loads_and_spawns_generated_map() -> void:
	GameState.start_run()
	GameState.player_map_pos = Vector2i(-1, -1)
	# Mesmo seed+fase que o manager usa → mapa idêntico (contrato determinístico).
	var expected := MapGenerator.new().generate(MapConfig.for_phase(1), GameState.map_seed_for_phase(1))

	var scene := preload("res://scenes/exploration/exploration.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame

	var enemies := scene.get_node("Enemies")
	assert_eq(enemies.get_child_count(), MapConfig.for_phase(1).enemy_count,
		"spawna todos os inimigos do mapa gerado (sem derrotados)")

	var caipora := scene.get_node("Caipora")
	assert_eq(caipora.position, Vector2(expected.player_start) * Constants.TILE_SIZE,
		"Caipora nasce no player_start do mapa gerado")

func test_phase1_tilemap_keeps_forest_atlases() -> void:
	# Protege o default do _profile.get(): só a Fase 5 troca para os tiles de igreja.
	GameState.start_run()
	GameState.player_map_pos = Vector2i(-1, -1)
	var scene := preload("res://scenes/exploration/exploration.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	var tile_set: TileSet = scene.get_node("TileMap").tile_set
	var floor_source := tile_set.get_source(0) as TileSetAtlasSource
	assert_eq(floor_source.texture.resource_path, "res://assets/sprites/tile_floor.png",
		"Fase 1 mantém o chão de floresta")

func test_phase1_skips_defeated_enemies() -> void:
	GameState.start_run()
	GameState.player_map_pos = Vector2i(-1, -1)
	var expected := MapGenerator.new().generate(MapConfig.for_phase(1), GameState.map_seed_for_phase(1))
	# Marca o primeiro inimigo como derrotado: não deve renascer.
	GameState.defeated_enemy_ids.append(expected.enemies[0]["id"])

	var scene := preload("res://scenes/exploration/exploration.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame

	var enemies := scene.get_node("Enemies")
	assert_eq(enemies.get_child_count(), MapConfig.for_phase(1).enemy_count - 1,
		"inimigo derrotado não renasce ao voltar da arena")
