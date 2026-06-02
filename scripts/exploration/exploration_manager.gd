extends Node2D

const MapObject := preload("res://scripts/exploration/map_object.gd")

# ─── Onready ───────────────────────────────────────
@onready var _tilemap: TileMap = $TileMap
@onready var _caipora: Caipora = $Caipora
@onready var _enemies_container: Node2D = $Enemies
@onready var _objects_container: Node2D = $Objects

# ─── State ─────────────────────────────────────────
var _map_enemies: Array[MapEnemy] = []
var _player_grid_pos: Vector2i = PLAYER_START
var _locked: bool = false
var _key_node: Node2D = null
var _chest_node: Node2D = null

# ─── Map Definition ────────────────────────────────
# 26 cols × 18 rows.
# W=wall  F=floor  E=exit
# C=baú   K=chave
# R=fogo  S=espinho
const MAP_LAYOUT = [
	"WWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WFFFFFFFFFWWWWWWWWWWWWWWWW",
	"WFFFFCFFFFWWWWWWWWWWWWWWWW",  # baú em (5,2)
	"WFFFFFFFFFWWWWWWWWWWWWWWWW",
	"WWWWWWFFFFFFFFFFWWWWWWWWWW",
	"WWWWWWWWWWWWWWWFWWWWWWWWWW",
	"WWWWWWWWWWWWWWWSWWWWWWWWWW",  # espinho (15,6)
	"WWWWWWWWWWWWWWWFWWWWWWWWWW",
	"WWWWWWWWWWWWWWWFFFFFFFFWWW",
	"WWWWWWWWWWWWWWWFFFFFFFFWWW",
	"WWWWWWWWWWWWWWWFRFFFFFFWWW",  # fogo (16,10)
	"WWWWWWWWWWWWWWWFFFFFFFFWWW",
	"WWWWWWWWWWWWWWWWWWWWFWWWWW",
	"WWWWWWWWWWWWWWWWWWWWSWWWWW",  # espinho (20,13)
	"WWWWWWWWWWWWWWWWWWWWFWWWWW",
	"WWWWWWWWWWWWWWWWWFFFFFFWWW",
	"WWWWWWWWWWWWWWWWWKFFFEWWWW",  # chave (17,16), saída (21,16)
	"WWWWWWWWWWWWWWWWWWWWWWWWWW",
]

const ENEMY_DEFS = [
	{"id": "e0", "x": 8,  "y": 2,  "boss": false},
	{"id": "e1", "x": 15, "y": 8,  "boss": false},
	{"id": "e2", "x": 21, "y": 11, "boss": false},
	{"id": "e3", "x": 18, "y": 15, "boss": true},
]

const EXIT_POS     := Vector2i(21, 16)
const CHEST_POS    := Vector2i(5,  2)
const KEY_POS      := Vector2i(17, 16)
const PLAYER_START := Vector2i(2,  2)

const HAZARD_CHARS := ["R", "S"]

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	_setup_tilemap()
	_setup_player()
	_spawn_enemies()
	_spawn_objects()
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

func _spawn_objects() -> void:
	# Baú
	if not GameState.chest_opened:
		var chest := _make_object(MapObject.Type.CHEST, CHEST_POS)
		_chest_node = chest

	# Chave
	if not GameState.has_key:
		var key := _make_object(MapObject.Type.KEY, KEY_POS)
		_key_node = key

	# Hazards do mapa (sempre presentes)
	for y: int in MAP_LAYOUT.size():
		var row: String = MAP_LAYOUT[y]
		for x: int in row.length():
			var ch: String = row[x]
			if ch == "R" or ch == "S":
				var t: MapObject.Type = MapObject.Type.FIRE if ch == "R" else MapObject.Type.SPIKE
				_make_object(t, Vector2i(x, y))

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

	# Saída
	if new_grid_pos == EXIT_POS:
		_locked = true
		GameState.change_screen(SignalBus.Screen.WIN)
		return

	# Chave
	if new_grid_pos == KEY_POS and not GameState.has_key:
		GameState.has_key = true
		if _key_node != null:
			_key_node.visible = false

	# Baú
	if new_grid_pos == CHEST_POS and not GameState.chest_opened:
		if GameState.has_key:
			_open_chest()

	# Colisão com inimigo
	for enemy in _map_enemies:
		if enemy.grid_pos == new_grid_pos:
			_trigger_combat(enemy)
			return

	# Hazard
	var row: String = MAP_LAYOUT[new_grid_pos.y]
	if new_grid_pos.x < row.length() and row[new_grid_pos.x] in HAZARD_CHARS:
		_apply_hazard_damage()
		if _locked:
			return

	_run_enemy_turns()

func _open_chest() -> void:
	GameState.chest_opened = true
	GameState.caipora_max_hp += 1
	GameState.caipora_current_hp = mini(GameState.caipora_current_hp + 1, GameState.caipora_max_hp)
	SignalBus.caipora_health_changed.emit(GameState.caipora_current_hp, GameState.caipora_max_hp)
	if _chest_node != null:
		_chest_node.visible = false

func _apply_hazard_damage() -> void:
	GameState.caipora_current_hp = maxi(0, GameState.caipora_current_hp - 1)
	SignalBus.caipora_health_changed.emit(GameState.caipora_current_hp, GameState.caipora_max_hp)
	if GameState.caipora_current_hp <= 0:
		_locked = true
		GameState.change_screen(SignalBus.Screen.GAME_OVER)

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

func _make_object(type: MapObject.Type, grid_pos: Vector2i) -> Node2D:
	var obj := MapObject.new()
	_objects_container.add_child(obj)
	obj.setup(type, grid_pos)
	return obj

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
	for y: int in range(MAP_LAYOUT.size()):
		var row: String = MAP_LAYOUT[y]
		for x: int in range(row.length()):
			var pos := Vector2i(x, y)
			if row[x] == "W":
				_tilemap.set_cell(0, pos, 1, Vector2i(0, 0))
			else:
				_tilemap.set_cell(0, pos, 0, Vector2i(0, 0))
