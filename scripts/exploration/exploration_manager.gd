extends Node2D

# ─── Onready ───────────────────────────────────────
@onready var _tilemap: TileMap = $TileMap
@onready var _caipora: Caipora = $Caipora
@onready var _enemies_container: Node2D = $Enemies

# ─── State ─────────────────────────────────────────
var _map_enemies: Array[MapEnemy] = []
var _player_grid_pos: Vector2i = PLAYER_START
var _locked: bool = false  # true while combat is triggering

# ─── Map Definition ────────────────────────────────
# 26 cols × 18 rows. W=wall, F=floor, E=exit (leads to win).
# Room 1 (start): cols 1-9, rows 1-3
# Corridor H:     cols 6-15, row 4
# Corridor V:     col 15, rows 5-7
# Room 2:         cols 15-22, rows 8-11
# Corridor V2:    col 20, rows 12-14
# Room 3 (boss):  cols 17-22, rows 15-16
const MAP_LAYOUT = [
	"WWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WFFFFFFFFFWWWWWWWWWWWWWWWW",
	"WFFFFFFFFFWWWWWWWWWWWWWWWW",
	"WFFFFFFFFFWWWWWWWWWWWWWWWW",
	"WWWWWWFFFFFFFFFFWWWWWWWWWW",
	"WWWWWWWWWWWWWWWFWWWWWWWWWW",
	"WWWWWWWWWWWWWWWFWWWWWWWWWW",
	"WWWWWWWWWWWWWWWFWWWWWWWWWW",
	"WWWWWWWWWWWWWWWFFFFFFFFWWW",
	"WWWWWWWWWWWWWWWFFFFFFFFWWW",
	"WWWWWWWWWWWWWWWFFFFFFFFWWW",
	"WWWWWWWWWWWWWWWFFFFFFFFWWW",
	"WWWWWWWWWWWWWWWWWWWWFWWWWW",
	"WWWWWWWWWWWWWWWWWWWWFWWWWW",
	"WWWWWWWWWWWWWWWWWWWWFWWWWW",
	"WWWWWWWWWWWWWWWWWFFFFFFWWW",
	"WWWWWWWWWWWWWWWWWFFFFEWWWW",
	"WWWWWWWWWWWWWWWWWWWWWWWWWW",
]

const ENEMY_DEFS = [
	{"id": "e0", "x": 8, "y": 2, "boss": false},
	{"id": "e1", "x": 15, "y": 8, "boss": false},
	{"id": "e2", "x": 21, "y": 11, "boss": false},
	{"id": "e3", "x": 18, "y": 15, "boss": true},
]

const EXIT_POS     := Vector2i(21, 16)
const PLAYER_START := Vector2i(2, 2)

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	_setup_tilemap()
	_setup_player()
	_spawn_enemies()
	_spawn_exit_marker()

func _setup_player() -> void:
	_player_grid_pos = PLAYER_START
	_caipora.tilemap = _tilemap
	_caipora.position = Vector2(PLAYER_START) * Constants.TILE_SIZE
	_caipora.move_finished.connect(_on_player_moved)

func _spawn_enemies() -> void:
	for def in ENEMY_DEFS:
		if def["id"] in GameState.defeated_enemy_ids:
			continue
		var enemy := MapEnemy.new()
		_enemies_container.add_child(enemy)
		enemy.setup(def["id"], Vector2i(def["x"], def["y"]), def["boss"])
		_map_enemies.append(enemy)

func _spawn_exit_marker() -> void:
	var marker := Sprite2D.new()
	marker.texture = preload("res://assets/sprites/tile_floor.png")
	marker.modulate = Color(1.0, 0.42, 0.0, 0.85)
	marker.position = Vector2(EXIT_POS) * Constants.TILE_SIZE
	add_child(marker)

# ─── Turn System ───────────────────────────────────
func _on_player_moved(new_grid_pos: Vector2i) -> void:
	if _locked:
		return
	_player_grid_pos = new_grid_pos

	if new_grid_pos == EXIT_POS:
		_locked = true
		GameState.change_screen(SignalBus.Screen.WIN)
		return

	for enemy in _map_enemies:
		if enemy.grid_pos == new_grid_pos:
			_trigger_combat(enemy)
			return

	_run_enemy_turns()

func _run_enemy_turns() -> void:
	for enemy in _map_enemies:
		var hit := enemy.take_turn(_player_grid_pos, _is_walkable, _is_occupied_by_enemy)
		if hit:
			_trigger_combat(enemy)
			return

func _trigger_combat(enemy: MapEnemy) -> void:
	_locked = true
	GameState.active_map_enemy_id = enemy.enemy_id
	GameState.active_combat_is_boss = enemy.is_boss
	if enemy.is_boss:
		GameState.next_enemy_scene = preload("res://scenes/arena/boss.tscn")
	GameState.change_screen(SignalBus.Screen.ARENA)

# ─── Walkability Helpers ───────────────────────────
func _is_walkable(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.y < 0 or pos.x >= Constants.GRID_WIDTH or pos.y >= Constants.GRID_HEIGHT:
		return false
	var row: String = MAP_LAYOUT[pos.y]
	return row[pos.x] != "W"

func _is_occupied_by_enemy(pos: Vector2i) -> bool:
	for enemy in _map_enemies:
		if enemy.grid_pos == pos:
			return true
	return false

# ─── TileMap Setup ─────────────────────────────────
func _setup_tilemap() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(Constants.TILE_SIZE, Constants.TILE_SIZE)

	tileset.add_physics_layer(0)
	tileset.set_physics_layer_collision_layer(0, 1 << (Constants.LAYER_WALL - 1))
	tileset.set_physics_layer_collision_mask(0, 1 << (Constants.LAYER_PLAYER - 1))

	var floor_source := TileSetAtlasSource.new()
	floor_source.texture = preload("res://assets/sprites/tile_floor.png")
	floor_source.texture_region_size = Vector2i(Constants.TILE_SIZE, Constants.TILE_SIZE)
	floor_source.create_tile(Vector2i(0, 0))
	tileset.add_source(floor_source, 0)

	var wall_source := TileSetAtlasSource.new()
	wall_source.texture = preload("res://assets/sprites/tile_wall.png")
	wall_source.texture_region_size = Vector2i(Constants.TILE_SIZE, Constants.TILE_SIZE)
	wall_source.create_tile(Vector2i(0, 0))
	tileset.add_source(wall_source, 1)

	_tilemap.tile_set = tileset
	_paint_map()

func _paint_map() -> void:
	for y in range(MAP_LAYOUT.size()):
		var row: String = MAP_LAYOUT[y]
		for x in range(row.length()):
			var pos := Vector2i(x, y)
			if row[x] == "W":
				_tilemap.set_cell(0, pos, 1, Vector2i(0, 0))
			else:
				_tilemap.set_cell(0, pos, 0, Vector2i(0, 0))
