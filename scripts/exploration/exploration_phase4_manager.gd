extends Node2D

const MapObject := preload("res://scripts/exploration/map_object.gd")
const FireEffect := preload("res://scripts/exploration/fire_effect.gd")

const SACI_SCENE        := preload("res://scenes/arena/saci.tscn")
const ASSOMBRACAO_SCENE := preload("res://scenes/arena/assombracao.tscn")
const DIALOGUE_SCENE    := preload("res://scenes/ui/dialogue_screen.tscn")

const SACI_DIALOGUE: Array[Dictionary] = [
	{"speaker": "CAIPORA", "text": "Vou salvar nossa casa"},
	{"speaker": "SACI",    "text": "Não pertenço mais..."},
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

# ─── Map Definition ────────────────────────────────
# 26 cols × 18 rows. A Casa consumida pelo fogo — esqueleto aberto da Fase 1
# (pilares de 1 tile + sala-chokepoint do boss no canto inferior-direito), mas
# tomada de chamas (R) por toda parte.
const MAP_LAYOUT = [
	"WWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WFFRFFFFRFFFFRFFFFRFFFFRFW",
	"WFFFWFFFFFFFWFFFFFFFWFFFFW",
	"WRFFFFFRFFFFFFFRFFFFFFFRFW",
	"WFFFFFFWFFWFFFFFFWFFFFFFFW",
	"WFFRFFFFRFFFRFFFRFFFFRFFFW",
	"WFFFWFFFFFWFFFFFWFFFFFFFFW",
	"WFFFFFFFWFFRFFFFRFFFFRFFFW",
	"WFFFFFFWFFFRFFFFFWFFFRFFFW",
	"WRFFFFFFFFFFFFFFFFFWFFFRFW",
	"WFFFWFFFFFWFFFFFWFFFFFFFFW",
	"WFFFFFWFFRFFFFFFRFFFFRFFFW",
	"WFFFFFFFFFFFFFFFFFWWWWWWWW",
	"WFFFFFFWFFFFFRFFFFWFFFFFFW",
	"WFFFFFFFFFFFFFFFFFFFFFFFFW",
	"WFFFWFFFFFFFFFFFFFWFRFRFFW",
	"WFFFFFFFFFRFFFFFFFWFFFFFFW",
	"WWWWWWWWWWWWWWWWWWWWWWWWWW",
]

const ENEMY_DEFS = [
	{"id": "p4_e0", "x": 9,  "y": 3,  "boss": false},
	{"id": "p4_e1", "x": 5,  "y": 9,  "boss": false},
	{"id": "p4_e2", "x": 14, "y": 8,  "boss": false},
	{"id": "p4_e3", "x": 20, "y": 3,  "boss": false},
	{"id": "p4_e4", "x": 12, "y": 13, "boss": false},
	{"id": "p4_e5", "x": 17, "y": 14, "boss": true, "type": "saci"},
]

const PLAYER_START := Vector2i(2, 1)

# A Caipora é feita de fogo: aura quente (luz + chama/brasas) a acompanha pela Casa.
const CAIPORA_AURA_LIGHT_SCALE: float = 1.5
const CAIPORA_AURA_OFFSET := Vector2(0, -10)

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	GameState.active_phase = 4
	_setup_tilemap()
	_setup_player()
	_spawn_enemies()
	_spawn_objects()
	add_child(Atmosphere.new())

func _setup_player() -> void:
	var start := _find_safe_spawn(PLAYER_START)
	_player_grid_pos = start
	_caipora.tilemap = _tilemap
	_caipora.position = Vector2(start) * Constants.TILE_SIZE
	_caipora.move_finished.connect(_on_player_moved)
	FireEffect.attach(_caipora, CAIPORA_AURA_OFFSET, CAIPORA_AURA_LIGHT_SCALE)

func _spawn_enemies() -> void:
	for def in ENEMY_DEFS:
		if def["id"] in GameState.defeated_enemy_ids:
			continue
		var enemy := MapEnemy.new()
		_enemies_container.add_child(enemy)
		enemy.setup(def["id"], Vector2i(def["x"], def["y"]), def.get("boss", false), def.get("type", ""))
		_map_enemies.append(enemy)

func _spawn_objects() -> void:
	for y: int in MAP_LAYOUT.size():
		var row: String = MAP_LAYOUT[y]
		for x: int in row.length():
			if row[x] == "R":
				_make_object(MapObject.Type.FIRE, Vector2i(x, y))

# ─── Turn System ───────────────────────────────────
func _on_player_moved(new_grid_pos: Vector2i) -> void:
	if _locked:
		return
	_player_grid_pos = new_grid_pos

	for enemy in _map_enemies:
		if enemy.grid_pos == new_grid_pos:
			_trigger_combat(enemy)
			return

	var row: String = MAP_LAYOUT[new_grid_pos.y]
	if new_grid_pos.x < row.length() and row[new_grid_pos.x] == "R":
		_apply_fire_damage()
		if _locked:
			return

	_run_enemy_turns()

func _apply_fire_damage() -> void:
	GameState.caipora_current_hp = maxi(0, GameState.caipora_current_hp - Constants.FIRE_TILE_DAMAGE)
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
	GameState.player_map_pos = Vector2i(-1, -1)
	GameState.active_map_enemy_id = enemy.enemy_id
	GameState.active_combat_is_boss = enemy.is_boss
	if enemy.is_boss:
		GameState.next_enemy_scene = SACI_SCENE
		_show_boss_dialogue()
	else:
		GameState.next_enemy_scene = ASSOMBRACAO_SCENE
		GameState.change_screen(SignalBus.Screen.ARENA_PHASE4)

func _show_boss_dialogue() -> void:
	var dlg: DialogueScreen = DIALOGUE_SCENE.instantiate()
	add_child(dlg)
	SignalBus.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
	dlg.start("SACI", SACI_DIALOGUE, "CAIPORA", Constants.COLOR_DIALOGUE_CAIPORA, Constants.COLOR_DIALOGUE_SACI)

func _on_dialogue_finished() -> void:
	GameState.change_screen(SignalBus.Screen.ARENA_PHASE4)

# ─── Spawn Helpers ─────────────────────────────────
func _spawn_is_safe(pos: Vector2i) -> bool:
	var dirs: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for d in dirs:
		var neighbor := pos + d
		if neighbor.y >= 0 and neighbor.y < MAP_LAYOUT.size():
			var row: String = MAP_LAYOUT[neighbor.y]
			if neighbor.x >= 0 and neighbor.x < row.length():
				if row[neighbor.x] == "R":
					return false
	return true

func _find_safe_spawn(preferred: Vector2i) -> Vector2i:
	if _spawn_is_safe(preferred):
		return preferred
	var queue: Array[Vector2i] = [preferred]
	var visited: Dictionary = {}
	var dirs: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	while not queue.is_empty():
		var pos: Vector2i = queue.pop_front()
		if visited.has(pos):
			continue
		visited[pos] = true
		if _is_walkable(pos) and _spawn_is_safe(pos):
			return pos
		for d in dirs:
			var next := pos + d
			if not visited.has(next) and _is_walkable(next):
				queue.append(next)
	return preferred

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
