extends Node2D

const MapObject := preload("res://scripts/exploration/map_object.gd")
const FireEffect := preload("res://scripts/exploration/fire_effect.gd")

const CURUPIRA_SCENE   := preload("res://scenes/arena/curupira.tscn")
const ASSOMBRACAO_SCENE := preload("res://scenes/arena/assombracao.tscn")
const DIALOGUE_SCENE   := preload("res://scenes/ui/dialogue_screen.tscn")

# Variantes de tile no atlas (ver scripts/tools/gen_tiles.py).
const FLOOR_VARIANTS := 4
const WALL_VARIANTS := 2

# Decoração temática do Ventre da Mata: raízes, musgo, cipó, samambaia, cogumelo.
const DECO_THEME: Array[MapObject.Type] = [
	MapObject.Type.ROOTS, MapObject.Type.MOSS, MapObject.Type.VINE,
	MapObject.Type.FERN, MapObject.Type.MUSHROOM,
]

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
# Ventre da Mata gerado proceduralmente (corredores). Determinístico por
# (run_seed, fase) — a volta da arena regenera o MESMO mapa.
var _map: GeneratedMap
var _map_enemies: Array[MapEnemy] = []
var _player_grid_pos: Vector2i = Vector2i.ZERO
var _locked: bool = false
var _fog: FogOfWar

# A Caipora é feita de fogo: na neblina ela arde como fogueira viva, dobrando a
# visibilidade ao redor (área 2x a visão de jogo).
const FOG_REVEAL_RADIUS: float = 192.0       # dobro do padrão (96) — Caipora arde na névoa
const CAIPORA_AURA_LIGHT_SCALE: float = 1.5  # ~192px de raio iluminado ≈ o raio revelado
const CAIPORA_AURA_OFFSET := Vector2(0, -10) # = sprite.offset.y(-12) × scale(0.8); x=0

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	GameState.active_phase = 3
	_map = MapGenerator.new().generate(MapConfig.for_phase(3), GameState.map_seed_for_phase(3))
	_setup_tilemap()
	_setup_player()
	_spawn_enemies()
	_spawn_objects()
	_spawn_fog()
	add_child(Atmosphere.new())

func _setup_player() -> void:
	var preferred := GameState.player_map_pos if GameState.player_map_pos != Vector2i(-1, -1) else _map.player_start
	var start := _find_safe_spawn(preferred)
	_player_grid_pos = start
	_caipora.tilemap = _tilemap
	_caipora.position = Vector2(start) * Constants.TILE_SIZE
	_caipora.move_finished.connect(_on_player_moved)
	# Aura de fogo viva: luz quente + chama/brasas/fumaça seguem a Caipora pela névoa.
	FireEffect.attach(_caipora, CAIPORA_AURA_OFFSET, CAIPORA_AURA_LIGHT_SCALE)

func _spawn_enemies() -> void:
	for def: Dictionary in _map.enemies:
		if def["id"] in GameState.defeated_enemy_ids:
			continue
		var enemy := MapEnemy.new()
		_enemies_container.add_child(enemy)
		enemy.setup(def["id"], Vector2i(def["x"], def["y"]), def["boss"], def.get("boss_type", ""))
		_map_enemies.append(enemy)

func _spawn_objects() -> void:
	# Decoração temática (raízes/musgo/cipó), tipos determinísticos da paleta.
	var deco_rng := RandomNumberGenerator.new()
	deco_rng.seed = GameState.map_seed_for_phase(3) ^ 0xDEC0
	for pos: Vector2i in _map.decorations:
		var type: MapObject.Type = DECO_THEME[deco_rng.randi_range(0, DECO_THEME.size() - 1)]
		_make_object(type, pos)

	# Fogo do mapa
	for y: int in _map.tiles.size():
		var row: Array = _map.tiles[y]
		for x: int in row.size():
			if row[x] == "R":
				_make_object(MapObject.Type.FIRE, Vector2i(x, y))

func _spawn_fog() -> void:
	_fog = FogOfWar.new()
	add_child(_fog)
	_fog.reveal_radius = FOG_REVEAL_RADIUS
	_fog.track(_caipora)
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

	if _map.char_at(new_grid_pos) == "R":
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
		GameState.next_enemy_scene = CURUPIRA_SCENE
		_show_boss_dialogue()
	else:
		GameState.next_enemy_scene = ASSOMBRACAO_SCENE
		GameState.change_screen(SignalBus.Screen.ARENA_PHASE3)

func _show_boss_dialogue() -> void:
	var dlg: DialogueScreen = DIALOGUE_SCENE.instantiate()
	add_child(dlg)
	SignalBus.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
	dlg.start("CURUPIRA", CURUPIRA_DIALOGUE, "CAIPORA", Constants.COLOR_DIALOGUE_CAIPORA, Constants.COLOR_DIALOGUE_CURUPIRA)

func _on_dialogue_finished() -> void:
	GameState.change_screen(SignalBus.Screen.ARENA_PHASE3)

# ─── Spawn Helpers ─────────────────────────────────
func _spawn_is_safe(pos: Vector2i) -> bool:
	# Spawn longe de fogo: nenhum vizinho imediato é hazard.
	for d: Vector2i in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
		if _map.char_at(pos + d) == "R":
			return false
	return true

func _find_safe_spawn(preferred: Vector2i) -> Vector2i:
	if _is_walkable(preferred) and _spawn_is_safe(preferred):
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
	# Fonte ÚNICA de verdade: o mapa gerado (o TileMap é pintado a partir dele).
	return _map.is_walkable(pos)

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
	for y: int in _map.tiles.size():
		var row: Array = _map.tiles[y]
		for x: int in row.size():
			var pos := Vector2i(x, y)
			if row[x] == "W":
				var wv: int = (x * 5 + y * 11) % WALL_VARIANTS
				_tilemap.set_cell(0, pos, 1, Vector2i(wv, 0))
			else:
				var fv: int = (x * 7 + y * 13) % FLOOR_VARIANTS
				_tilemap.set_cell(0, pos, 0, Vector2i(fv, 0))
