class_name TestCaiporaMovement
extends GutTest

var _caipora: Caipora

func before_each():
	_caipora = preload("res://scenes/exploration/caipora.tscn").instantiate()
	_caipora.position = Vector2(32, 32)
	# Mock tilemap: cria TileMap simples sem paredes no caminho do teste
	var tilemap := TileMap.new()
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(32, 32)
	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(0, "is_arena_trigger")
	tileset.set_custom_data_layer_type(0, 0)
	var source := TileSetAtlasSource.new()
	source.texture = preload("res://assets/sprites/tile_floor.png")
	source.texture_region_size = Vector2i(32, 32)
	source.create_tile(Vector2i(0, 0))
	tileset.add_source(source, 0)
	tilemap.tile_set = tileset
	# Pintar chão nas posições dos testes
	tilemap.set_cell(0, Vector2i(1, 1), 0, Vector2i(0, 0))  # spawn
	tilemap.set_cell(0, Vector2i(2, 1), 0, Vector2i(0, 0))  # direita
	tilemap.set_cell(0, Vector2i(1, 0), 0, Vector2i(0, 0))  # cima
	_caipora.tilemap = tilemap
	add_child_autofree(tilemap)
	add_child_autofree(_caipora)

func test_move_right_increases_x():
	_caipora._try_move(Vector2.RIGHT)
	await get_tree().create_timer(0.2).timeout
	assert_eq(_caipora.position.x, 64.0)
	assert_eq(_caipora.position.y, 32.0)

func test_move_up_decreases_y():
	_caipora._try_move(Vector2.UP)
	await get_tree().create_timer(0.2).timeout
	assert_eq(_caipora.position.x, 32.0)
	assert_eq(_caipora.position.y, 0.0)

func test_wall_blocks_move():
	# Adicionar source de parede ao tileset
	var wall_source := TileSetAtlasSource.new()
	wall_source.texture = preload("res://assets/sprites/tile_wall.png")
	wall_source.texture_region_size = Vector2i(32, 32)
	wall_source.create_tile(Vector2i(0, 0))
	_caipora.tilemap.tile_set.add_source(wall_source, 1)
	# Pintar parede em (3, 1)
	_caipora.tilemap.set_cell(0, Vector2i(3, 1), 1, Vector2i(0, 0))

	_caipora.position = Vector2(64, 32)
	_caipora._try_move(Vector2.RIGHT)
	await get_tree().create_timer(0.2).timeout
	assert_eq(_caipora.position.x, 64.0)  # não moveu
	assert_eq(_caipora.position.y, 32.0)
