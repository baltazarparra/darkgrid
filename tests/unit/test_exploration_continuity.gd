extends GutTest

# Continuidade do mapa entre exploração → arena → exploração: ao voltar do combate,
# inimigos sobreviventes e o jogador devem reaparecer EXATAMENTE onde estavam (o mapa
# é o mesmo de antes). O movimento dos inimigos é não-determinístico, então a posição
# vem de um snapshot (GameState.map_enemy_positions / player_map_pos), não da regeração.

func after_each() -> void:
	GameState.player_map_pos = Vector2i(-1, -1)
	GameState.map_enemy_positions.clear()
	GameState.defeated_enemy_ids.clear()

func _enemy_grid_pos(scene: Node, id: String) -> Vector2i:
	for e in scene.get_node("Enemies").get_children():
		if e.enemy_id == id:
			return e.grid_pos
	return Vector2i(-999, -999)

func _walkable_near_fire(m: GeneratedMap) -> Vector2i:
	# Célula caminhável colada em fogo — prova que a restauração ignora o safe_spawn.
	for y: int in m.tiles.size():
		var row: Array = m.tiles[y]
		for x: int in row.size():
			var p := Vector2i(x, y)
			if not m.is_walkable(p) or p == m.player_start:
				continue
			for d: Vector2i in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
				if m.char_at(p + d) == "R":
					return p
	return m.player_start

# ── Inimigo sobrevivente volta na posição "andada", não no spawn do mapa ──
func test_enemy_restored_to_snapshot_position() -> void:
	GameState.start_run()
	var expected := MapGenerator.new().generate(MapConfig.for_phase(4), GameState.map_seed_for_phase(4))

	var target_id: String = ""
	var spawn := Vector2i.ZERO
	for e: Dictionary in expected.enemies:
		if not e["boss"]:
			target_id = e["id"]
			spawn = Vector2i(e["x"], e["y"])
			break
	var wandered := spawn + Vector2i(0, -1)  # finge que o inimigo andou uma casa
	GameState.map_enemy_positions = {target_id: wandered}

	var scene := preload("res://scenes/exploration/exploration_phase4.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame

	assert_eq(_enemy_grid_pos(scene, target_id), wandered,
		"inimigo restaurado onde estava antes do combate (não no spawn)")

# ── Inimigo SEM snapshot usa o spawn do mapa (entrada fresca / outro inimigo) ──
func test_enemy_without_snapshot_uses_spawn() -> void:
	GameState.start_run()
	var expected := MapGenerator.new().generate(MapConfig.for_phase(4), GameState.map_seed_for_phase(4))
	var some: Dictionary = expected.enemies[0]
	var spawn := Vector2i(some["x"], some["y"])

	var scene := preload("res://scenes/exploration/exploration_phase4.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame

	assert_eq(_enemy_grid_pos(scene, some["id"]), spawn,
		"sem snapshot, inimigo nasce na posição de spawn do mapa gerado")

# ── Jogador volta EXATAMENTE onde estava, mesmo com safe_spawn ligado (Fase 4) ──
func test_player_restored_exactly_even_with_safe_spawn() -> void:
	GameState.start_run()
	var expected := MapGenerator.new().generate(MapConfig.for_phase(4), GameState.map_seed_for_phase(4))
	var unsafe := _walkable_near_fire(expected)
	GameState.player_map_pos = unsafe

	var scene := preload("res://scenes/exploration/exploration_phase4.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame

	assert_eq(scene.get_node("Caipora").position, Vector2(unsafe) * Constants.TILE_SIZE,
		"jogador restaurado na posição exata (safe_spawn não realoca na volta do combate)")
