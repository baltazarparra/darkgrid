extends Node2D

const MapObject := preload("res://scripts/exploration/map_object.gd")
const ForestLight := preload("res://scripts/exploration/forest_light.gd")
const ForestAmbience := preload("res://scripts/exploration/forest_ambience.gd")

# Variantes de tile no atlas (ver scripts/tools/gen_tiles.py).
const FLOOR_VARIANTS := 4
const WALL_VARIANTS := 2

# ─── Onready ───────────────────────────────────────
@onready var _tilemap: TileMap = $TileMap
@onready var _caipora: Caipora = $Caipora
@onready var _enemies_container: Node2D = $Enemies
@onready var _objects_container: Node2D = $Objects

# ─── State ─────────────────────────────────────────
# Mapa gerado proceduralmente a cada run. Determinístico por (run_seed, fase) — a
# volta da arena regenera o MESMO mapa, então inimigos derrotados continuam fora.
var _map: GeneratedMap
var _map_enemies: Array[MapEnemy] = []
var _player_grid_pos: Vector2i = Vector2i.ZERO
var _locked: bool = false
var _key_node: Node2D = null
var _chest_node: Node2D = null

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	GameState.active_phase = 1
	_map = MapGenerator.new().generate(MapConfig.for_phase(1), GameState.map_seed_for_phase(1))
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
	var area := Rect2(
		t, t,
		(Constants.GRID_WIDTH - 2) * t,
		(Constants.GRID_HEIGHT - 2) * t
	)
	var life := AmbientLife.new()
	add_child(life)
	life.setup(area)
	# Camadas atmosféricas premium: neblina, esporos e god rays.
	var ambience := ForestAmbience.new()
	add_child(ambience)
	ambience.setup(area)

func _setup_player() -> void:
	var start := GameState.player_map_pos if GameState.player_map_pos != Vector2i(-1, -1) else _map.player_start
	_player_grid_pos = start
	_caipora.tilemap = _tilemap
	_caipora.position = Vector2(start) * Constants.TILE_SIZE
	_caipora.move_finished.connect(_on_player_moved)
	# Tocha da Caipora: poça de luz fria (luar) que a segue, garante leitura na noite
	# fechada — rede de segurança do gameplay contra a vinheta + CanvasModulate escuros.
	var torch := ForestLight.make(Color(0.88, 0.93, 1.0), 1.25, 1.6)
	_caipora.add_child(torch)

func _spawn_enemies() -> void:
	for def: Dictionary in _map.enemies:
		if def["id"] in GameState.defeated_enemy_ids:
			continue
		var enemy := MapEnemy.new()
		_enemies_container.add_child(enemy)
		enemy.setup(def["id"], Vector2i(def["x"], def["y"]), def["boss"])
		_map_enemies.append(enemy)

func _spawn_objects() -> void:
	# Decorações de ambientação (atrás de tudo). Tipos sorteados de forma
	# determinística da paleta visual, estáveis na volta da arena.
	var deco_rng := RandomNumberGenerator.new()
	deco_rng.seed = GameState.map_seed_for_phase(1) ^ 0xDEC0
	var palette: Array = MapObject.DECO_TYPES
	for pos: Vector2i in _map.decorations:
		var type: MapObject.Type = palette[deco_rng.randi_range(0, palette.size() - 1)]
		_make_object(type, pos)

	# Baú
	if not GameState.chest_opened and _map.chest_pos != Vector2i(-1, -1):
		_chest_node = _make_object(MapObject.Type.CHEST, _map.chest_pos)

	# Chave
	if not GameState.has_key and _map.key_pos != Vector2i(-1, -1):
		_key_node = _make_object(MapObject.Type.KEY, _map.key_pos)

	# Hazards do mapa (sempre presentes)
	for y: int in _map.tiles.size():
		var row: Array = _map.tiles[y]
		for x: int in row.size():
			var ch: String = row[x]
			if ch == "R" or ch == "S":
				var t: MapObject.Type = MapObject.Type.FIRE if ch == "R" else MapObject.Type.SPIKE
				_make_object(t, Vector2i(x, y))

func _spawn_exit_marker() -> void:
	var center := Vector2(_map.exit_pos) * Constants.TILE_SIZE + Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE) * 0.5
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
	if new_grid_pos == _map.exit_pos:
		_locked = true
		GameState.player_map_pos = Vector2i(-1, -1)
		GameState.change_screen(SignalBus.Screen.EXPLORATION_PHASE2)
		return

	# Chave
	if new_grid_pos == _map.key_pos and not GameState.has_key:
		GameState.has_key = true
		if _key_node != null:
			_key_node.visible = false

	# Baú
	if new_grid_pos == _map.chest_pos and not GameState.chest_opened:
		if GameState.has_key:
			_open_chest()

	# Colisão com inimigo
	for enemy in _map_enemies:
		if enemy.grid_pos == new_grid_pos:
			_trigger_combat(enemy)
			return

	# Hazard
	if _map.char_at(new_grid_pos) in ["R", "S"]:
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
	# Fase 1 tem poucas fogueiras → realce (luz + partículas) ligado.
	obj.setup(type, grid_pos, true)
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
				# variante de parede determinística (hash de x,y) — copa mais/menos densa
				var wv: int = (x * 5 + y * 11) % WALL_VARIANTS
				_tilemap.set_cell(0, pos, 1, Vector2i(wv, 0))
			else:
				# variante de chão determinística — quebra o padrão de grade repetido
				var fv: int = (x * 7 + y * 13) % FLOOR_VARIANTS
				_tilemap.set_cell(0, pos, 0, Vector2i(fv, 0))
