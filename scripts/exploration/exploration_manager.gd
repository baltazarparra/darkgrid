extends Node2D

const MapObject := preload("res://scripts/exploration/map_object.gd")
const ForestLight := preload("res://scripts/exploration/forest_light.gd")

# Variantes de tile no atlas (ver scripts/tools/gen_tiles.py).
const FLOOR_VARIANTS := 4
const WALL_VARIANTS := 2

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
# Mapa aberto: grande área caminhável com pilares de 1 tile (cobertura/rota) e
# uma sala-chokepoint do boss no canto inferior-direito. A saída (E) fica dentro
# dela; a porta única é o gap em (17,14), onde o boss (e3) faz guarda.
const MAP_LAYOUT = [
	"WWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WFFFFFFFFFFFFFFFFFFFFFFFFW",
	"WFFFWFFFFFFFWFFFFFFFWFFFFW",
	"WFFFFFFFFFFFFFFFFFFFFFFFFW",
	"WFFFFFFWFFFFFFFFFWFFFFFFFW",
	"WFFFFFFFRFFFFFFSFFFFFFFFFW",  # fogo (8,5), espinho (15,5)
	"WFFFWFFFFFWFFFFFWFFFFFFFFW",
	"WFFFFFFFFFFFFFFFFFFFFFFFFW",
	"WFFFFFFWFFFRFFFFFWFFFSFFFW",  # fogo (11,8), espinho (21,8)
	"WFFFFFFFFFFFFFFFFFFFFFFFFW",
	"WFFFWFFFFFWFFFFFWFFFFFFFFW",
	"WFFFFFFFFSFFFFFFRFFFFFFFFW",  # espinho (9,11), fogo (16,11)
	"WFFFFFFFFFFFFFFFFFWWWWWWWW",
	"WFFFFFFWFFFFFSFFFFWFFFFFFW",  # espinho (12,13)
	"WFFFFFFFFFFFFFFFFFFFFFFFFW",  # porta do boss: gap em (17,14)
	"WFFFWFFFFFFFFFFFFFWFFFFFFW",
	"WFFFFFFFFFFFFFFFFFWFFFEFFW",  # saída (21,16) dentro da sala do boss
	"WWWWWWWWWWWWWWWWWWWWWWWWWW",
]

const ENEMY_DEFS = [
	{"id": "p1_e0", "x": 9,  "y": 3,  "boss": false},
	{"id": "p1_e1", "x": 12, "y": 9,  "boss": false},
	{"id": "p1_e2", "x": 18, "y": 6,  "boss": false},
	{"id": "p1_e3", "x": 17, "y": 14, "boss": true},  # guarda a porta da saída
]

const EXIT_POS     := Vector2i(21, 16)
const CHEST_POS    := Vector2i(6,  2)
const KEY_POS      := Vector2i(12, 7)  # perto de e1, pegável sem lutar
const PLAYER_START := Vector2i(2,  1)

const HAZARD_CHARS := ["R", "S"]

# Ambientação folk-horror (puramente visual, não afeta walkability).
const DECO_DEFS = [
	{"type": MapObject.Type.DEAD_TREE, "x": 2, "y": 3},
	{"type": MapObject.Type.DEAD_TREE, "x": 23, "y": 2},
	{"type": MapObject.Type.DEAD_TREE, "x": 2, "y": 14},
	{"type": MapObject.Type.DEAD_TREE, "x": 23, "y": 9},
	{"type": MapObject.Type.ROCK, "x": 5, "y": 2},
	{"type": MapObject.Type.ROCK, "x": 22, "y": 5},
	{"type": MapObject.Type.ROCK, "x": 6, "y": 15},
	{"type": MapObject.Type.ROCK, "x": 20, "y": 3},
	{"type": MapObject.Type.MOSS, "x": 9, "y": 6},
	{"type": MapObject.Type.MOSS, "x": 14, "y": 7},
	{"type": MapObject.Type.MOSS, "x": 8, "y": 9},
	{"type": MapObject.Type.MOSS, "x": 13, "y": 10},
	{"type": MapObject.Type.MOSS, "x": 16, "y": 9},
	{"type": MapObject.Type.MOSS, "x": 11, "y": 4},
	{"type": MapObject.Type.BONES, "x": 13, "y": 5},
	{"type": MapObject.Type.BONES, "x": 20, "y": 8},
	{"type": MapObject.Type.BONES, "x": 10, "y": 11},
	{"type": MapObject.Type.BLOOD_POOL, "x": 12, "y": 13},
	{"type": MapObject.Type.BLOOD_POOL, "x": 19, "y": 15},
	{"type": MapObject.Type.BLOOD_POOL, "x": 15, "y": 14},
	{"type": MapObject.Type.BONES, "x": 20, "y": 15},
	{"type": MapObject.Type.FERN, "x": 5, "y": 7},
	{"type": MapObject.Type.FERN, "x": 19, "y": 4},
	{"type": MapObject.Type.FERN, "x": 7, "y": 12},
	{"type": MapObject.Type.FERN, "x": 22, "y": 11},
	{"type": MapObject.Type.FERN, "x": 14, "y": 16},
	{"type": MapObject.Type.VINE, "x": 10, "y": 2},
	{"type": MapObject.Type.VINE, "x": 18, "y": 1},
	{"type": MapObject.Type.VINE, "x": 6, "y": 4},
	{"type": MapObject.Type.VINE, "x": 21, "y": 7},
]

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	_setup_tilemap()
	_setup_player()
	_spawn_enemies()
	_spawn_objects()
	_spawn_exit_marker()
	_spawn_ambient_life()
	add_child(Atmosphere.new())

func _spawn_ambient_life() -> void:
	# Vaga-lumes + insetos sobre a área interna do mapa (decorativo, sem interação).
	var t := Constants.TILE_SIZE
	var life := AmbientLife.new()
	add_child(life)
	life.setup(Rect2(
		t, t,
		(Constants.GRID_WIDTH - 2) * t,
		(Constants.GRID_HEIGHT - 2) * t
	))

func _setup_player() -> void:
	var start := GameState.player_map_pos if GameState.player_map_pos != Vector2i(-1, -1) else PLAYER_START
	_player_grid_pos = start
	_caipora.tilemap = _tilemap
	_caipora.position = Vector2(start) * Constants.TILE_SIZE
	_caipora.move_finished.connect(_on_player_moved)
	# Tocha da Caipora: poça de luz fria (luar) que a segue, garante leitura na noite
	# fechada — rede de segurança do gameplay contra a vinheta + CanvasModulate escuros.
	var torch := ForestLight.make(Color(0.88, 0.93, 1.0), 1.25, 1.6)
	_caipora.add_child(torch)

func _spawn_enemies() -> void:
	for def in ENEMY_DEFS:
		if def["id"] in GameState.defeated_enemy_ids:
			continue
		var enemy := MapEnemy.new()
		_enemies_container.add_child(enemy)
		enemy.setup(def["id"], Vector2i(def["x"], def["y"]), def["boss"])
		_map_enemies.append(enemy)

func _spawn_objects() -> void:
	# Decorações de ambientação (atrás de tudo)
	for d in DECO_DEFS:
		_make_object(d["type"], Vector2i(d["x"], d["y"]))

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
	var center := Vector2(EXIT_POS) * Constants.TILE_SIZE + Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE) * 0.5
	var marker := Sprite2D.new()
	marker.texture = preload("res://assets/sprites/tile_floor.png")
	marker.modulate = Constants.COLOR_EXIT
	marker.position = center - Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE) * 0.5
	add_child(marker)
	# Luz âmbar pulsante: marca a saída na escuridão sem precisar de texto.
	var light := ForestLight.make(Constants.COLOR_AMBER, 1.0, 1.0)
	light.position = center
	add_child(light)
	var tween := create_tween().set_loops()
	tween.tween_property(light, "energy", 1.4, 1.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(light, "energy", 0.7, 1.1).set_trans(Tween.TRANS_SINE)

# ─── Turn System ───────────────────────────────────
func _on_player_moved(new_grid_pos: Vector2i) -> void:
	if _locked:
		return
	_player_grid_pos = new_grid_pos

	# Saída — avança para a Fase 2
	if new_grid_pos == EXIT_POS:
		_locked = true
		GameState.player_map_pos = Vector2i(-1, -1)
		GameState.change_screen(SignalBus.Screen.EXPLORATION_PHASE2)
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
	SignalBus.chest_opened.emit()
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
	GameState.player_map_pos = _player_grid_pos
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
	for i: int in FLOOR_VARIANTS:
		floor_source.create_tile(Vector2i(i, 0))
	tileset.add_source(floor_source, 0)

	var wall_source := TileSetAtlasSource.new()
	wall_source.texture = preload("res://assets/sprites/tile_wall.png")
	wall_source.texture_region_size = Vector2i(Constants.TILE_SIZE, Constants.TILE_SIZE)
	for i: int in WALL_VARIANTS:
		wall_source.create_tile(Vector2i(i, 0))
	tileset.add_source(wall_source, 1)

	_tilemap.tile_set = tileset
	_paint_map()

func _paint_map() -> void:
	for y: int in range(MAP_LAYOUT.size()):
		var row: String = MAP_LAYOUT[y]
		for x: int in range(row.length()):
			var pos := Vector2i(x, y)
			if row[x] == "W":
				# variante de parede determinística (hash de x,y) — copa mais/menos densa
				var wv: int = (x * 5 + y * 11) % WALL_VARIANTS
				_tilemap.set_cell(0, pos, 1, Vector2i(wv, 0))
			else:
				# variante de chão determinística — quebra o padrão de grade repetido
				var fv: int = (x * 7 + y * 13) % FLOOR_VARIANTS
				_tilemap.set_cell(0, pos, 0, Vector2i(fv, 0))
