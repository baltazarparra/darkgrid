extends Node2D

# ─── Onready ───────────────────────────────────────
@onready var _tilemap: TileMap = $TileMap
@onready var _caipora: Caipora = $Caipora

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	_setup_tilemap()
	_caipora.tilemap = _tilemap
	_caipora.position = Vector2(1, 1) * Constants.TILE_SIZE
	SignalBus.arena_entered.connect(_on_arena_entered)

# ─── TileMap Setup ─────────────────────────────────
func _setup_tilemap() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(Constants.TILE_SIZE, Constants.TILE_SIZE)

	# Physics layer 0: walls
	tileset.add_physics_layer(0)
	tileset.set_physics_layer_collision_layer(0, 1 << (Constants.LAYER_WALL - 1))
	tileset.set_physics_layer_collision_mask(0, 1 << (Constants.LAYER_PLAYER - 1))

	# Custom data layer: arena trigger
	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(0, "is_arena_trigger")
	tileset.set_custom_data_layer_type(0, 0)  # TYPE_BOOL = 0

	# Atlas source: floor
	var floor_tex := preload("res://assets/sprites/tile_floor.png")
	var floor_source := TileSetAtlasSource.new()
	floor_source.texture = floor_tex
	floor_source.texture_region_size = Vector2i(Constants.TILE_SIZE, Constants.TILE_SIZE)
	floor_source.create_tile(Vector2i(0, 0))
	tileset.add_source(floor_source, 0)

	# Atlas source: wall
	var wall_tex := preload("res://assets/sprites/tile_wall.png")
	var wall_source := TileSetAtlasSource.new()
	wall_source.texture = wall_tex
	wall_source.texture_region_size = Vector2i(Constants.TILE_SIZE, Constants.TILE_SIZE)
	wall_source.create_tile(Vector2i(0, 0))
	tileset.add_source(wall_source, 1)

	_tilemap.tile_set = tileset

	# Paint the map
	_paint_map()

func _paint_map() -> void:
	# 20x15 grid
	# W = wall (source 1), F = floor (source 0), T = trigger (source 0 + custom_data)
	var map_layout := [
		"WWWWWWWWWWWWWWWWWWWW",
		"WFFFFFFFFFFWFFFFFFFW",
		"WFFFFFFFFFFWFFFFFFFW",
		"WFFFFFFFFFFWFFFFFFFW",
		"WFFFFWFFFFFFWFFFFFFW",
		"WFFFFWFFFFFFFFFFFFFW",
		"WFFFFWFFFFFFFFFFFFFW",
		"WFFFFWFFFFFFFFFFFFFW",
		"WFFFFFFFFFFFFWFFFFFW",
		"WFFFFFFFFFFFFWFFFFFW",
		"WFFFFFFFFFFFFWFFFFFW",
		"WFFFFFFFFFFFFWFFFFFW",
		"WFFFFFFFFFFFFFFFFTFW",
		"WFFFFFFFFFFFFFFFFFFW",
		"WWWWWWWWWWWWWWWWWWWW",
	]

	# Single source of truth: the "T" in the layout IS the arena trigger.
	var trigger_pos := Vector2i(-1, -1)
	for y in range(map_layout.size()):
		var row: String = map_layout[y]
		for x in range(row.length()):
			var cell: String = row[x]
			var pos := Vector2i(x, y)
			match cell:
				"W":
					_tilemap.set_cell(0, pos, 1, Vector2i(0, 0))
				"T":
					_tilemap.set_cell(0, pos, 0, Vector2i(0, 0))
					trigger_pos = pos
				_:
					_tilemap.set_cell(0, pos, 0, Vector2i(0, 0))

	# Mark the trigger tile (derived from layout) with custom data
	if trigger_pos != Vector2i(-1, -1):
		var trigger_data := _tilemap.get_cell_tile_data(0, trigger_pos)
		if trigger_data:
			trigger_data.set_custom_data("is_arena_trigger", true)

# ─── Signal Handlers ───────────────────────────────
func _on_arena_entered(arena_id: String) -> void:
	GameState.change_screen(SignalBus.Screen.ARENA)
