extends Node2D

const MapObject := preload("res://scripts/exploration/map_object.gd")

const CURUPIRA_SCENE   := preload("res://scenes/arena/curupira.tscn")
const ASSOMBRACAO_SCENE := preload("res://scenes/arena/assombracao.tscn")
const DIALOGUE_SCENE   := preload("res://scenes/ui/dialogue_screen.tscn")

const CURUPIRA_DIALOGUE: Array[Dictionary] = [
	{"speaker": "CAIPORA",  "text": "ninguém te deixou..."},
	{"speaker": "CURUPIRA", "text": "isso pouco importa agora"},
]

# ─── Onready ───────────────────────────────────────
@onready var _tilemap: TileMap = $TileMap
@onready var _caipora: Caipora = $Caipora
@onready var _enemies_container: Node2D = $Enemies
@onready var _objects_container: Node2D = $Objects

# ─── State ─────────────────────────────────────────
var _map_enemies: Array[MapEnemy] = []
var _player_grid_pos: Vector2i = PLAYER_START
var _locked: bool = false
var _fog: FogOfWar

# ─── Map Definition ────────────────────────────────
# 26 cols × 18 rows. Ventre da Mata — raízes, corredores estreitos, sem fogo.
const MAP_LAYOUT = [
	"WWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WFFFFFFFFFFFFFFFFFFFFFFFFW",
	"WFWWWWFFFFFFFFFFFFWWWWFFFW",
	"WFFWWFFFFFFFFFFFFFFFFFWWWW",
	"WFWWWFFFFFFFFFFFFWWWWWFFFW",
	"WFFFFFFWWWWFFFFFFFFFFFFFFW",
	"WWWWWFFFFFFFWWWWWFFFFFFFFW",
	"WFFFWWWWWFFFFWWWWFFFFFFFFW",
	"WFFFFFFFFFWWWFFFWWWFFFFFFFW",
	"WWWFFFWWWFFFFFFFWWWWFFFFFW",
	"WFFFFFFFFFFFFFFWWWFFFFFFFW",
	"WWWWFFFFFFFFFFFWWWFFFFFFFW",
	"WFFFFWWWWWFFFFFFFFFWWWWWWW",
	"WFFFFFFFFFFFWWWWFFFFFFFFFW",
	"WFFFFFFFFFFFFFFFFFFFFWWFFW",
	"WWWWFFFFFWWWWFFFFFFWWWWWWW",
	"WFFFFFFFFFFFFFFFFFFFFFFFFW",
	"WWWWWWWWWWWWWWWWWWWWWWWWWW",
]

const ENEMY_DEFS = [
	{"id": "e0", "x": 9,  "y": 3,  "boss": false},
	{"id": "e1", "x": 14, "y": 8,  "boss": false},
	{"id": "e2", "x": 19, "y": 5,  "boss": false},
	{"id": "e3", "x": 17, "y": 14, "boss": true},
]

const PLAYER_START := Vector2i(2, 1)

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	GameState.active_phase = 3
	_setup_tilemap()
	_setup_player()
	_spawn_enemies()
	_spawn_objects()
	_spawn_fog()
	add_child(Atmosphere.new())

func _setup_player() -> void:
	var start := GameState.player_map_pos if GameState.player_map_pos != Vector2i(-1, -1) else PLAYER_START
	_player_grid_pos = start
	_caipora.tilemap = _tilemap
	_caipora.position = Vector2(start) * Constants.TILE_SIZE
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
	pass

func _spawn_exit_marker() -> void:
	pass

func _spawn_fog() -> void:
	_fog = FogOfWar.new()
	add_child(_fog)
	var cam: Camera2D = _caipora.get_node_or_null("Camera2D")
	if cam == null:
		cam = Camera2D.new()
	_update_fog()

func _update_fog() -> void:
	if _fog == null:
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var world_center := Vector2(_player_grid_pos) * Constants.TILE_SIZE + Vector2(Constants.TILE_SIZE * 0.5, Constants.TILE_SIZE * 0.5)
	_fog.update_position(world_center, cam)

# ─── Turn System ───────────────────────────────────
func _on_player_moved(new_grid_pos: Vector2i) -> void:
	if _locked:
		return
	_player_grid_pos = new_grid_pos
	_update_fog()

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
	GameState.player_map_pos = _player_grid_pos
	GameState.active_map_enemy_id = enemy.enemy_id
	GameState.active_combat_is_boss = enemy.is_boss
	if enemy.is_boss:
		GameState.next_enemy_scene = CURUPIRA_SCENE
		_show_boss_dialogue()
	else:
		GameState.next_enemy_scene = ASSOMBRACAO_SCENE
		GameState.change_screen(SignalBus.Screen.ARENA_PHASE3)

func _show_boss_dialogue() -> void:
	var dlg: DialogueScreen = DIALOGUE_SCENE.instantiate()
	add_child(dlg)
	SignalBus.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
	dlg.start("CURUPIRA", CURUPIRA_DIALOGUE)

func _on_dialogue_finished() -> void:
	GameState.change_screen(SignalBus.Screen.ARENA_PHASE3)

# ─── Walkability Helpers ───────────────────────────
func _is_walkable(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.y < 0 or pos.x >= Constants.GRID_WIDTH or pos.y >= Constants.GRID_HEIGHT:
		return false
	var row: String = MAP_LAYOUT[pos.y]
	return pos.x < row.length() and row[pos.x] != "W"

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
