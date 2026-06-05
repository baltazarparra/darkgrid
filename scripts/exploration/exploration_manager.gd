extends Node2D

# Manager ÚNICO de exploração para as 4 fases. O comportamento por fase é DADO
# (composição, não herança): geração vem de MapConfig.for_phase(phase) e a
# apresentação/rota vem de _build_profile(). Cada cena .tscn aponta para este
# script e define `phase`. Cores do CanvasModulate ficam na própria cena.

const MapObject := preload("res://scripts/exploration/map_object.gd")
const ForestLight := preload("res://scripts/exploration/forest_light.gd")
const ForestAmbience := preload("res://scripts/exploration/forest_ambience.gd")
const FireEffect := preload("res://scripts/exploration/fire_effect.gd")

# Cenas de arena por fase.
const MULA_SCENE        := preload("res://scenes/arena/mula.tscn")
const BOITATA_SCENE     := preload("res://scenes/arena/boitata.tscn")
const CACADOR_SCENE     := preload("res://scenes/arena/cacador.tscn")
const CURUPIRA_SCENE    := preload("res://scenes/arena/curupira.tscn")
const ASSOMBRACAO_SCENE := preload("res://scenes/arena/assombracao.tscn")
const SACI_SCENE        := preload("res://scenes/arena/saci.tscn")
const DIALOGUE_SCENE    := preload("res://scenes/ui/dialogue_screen.tscn")

# Variantes de tile no atlas (ver scripts/tools/gen_tiles.py).
const FLOOR_VARIANTS := 4
const WALL_VARIANTS := 2

# Aura da Caipora pela névoa/casa (= sprite.offset.y(-12) × scale(0.8); x=0).
const CAIPORA_AURA_OFFSET := Vector2(0, -10)
const CAIPORA_AURA_LIGHT_SCALE: float = 1.5
const FOG_REVEAL_RADIUS: float = 192.0  # dobro do padrão — Caipora arde na névoa

enum Aura { NONE, TORCH, FIRE }
enum ExitMarker { NONE, SIMPLE, PULSING }

# Paletas de decoração temáticas.
const DECO_FOREST: Array[MapObject.Type] = [
	MapObject.Type.ROOTS, MapObject.Type.MOSS, MapObject.Type.VINE,
	MapObject.Type.FERN, MapObject.Type.MUSHROOM,
]
const DECO_FIRE: Array[MapObject.Type] = [
	MapObject.Type.DEAD_TREE, MapObject.Type.BONES, MapObject.Type.STUMP,
	MapObject.Type.BLOOD_POOL, MapObject.Type.ROCK,
]

const MULA_DIALOGUE: Array[Dictionary] = [
	{"speaker": "CAIPORA", "text": "Vim terminar o que comecei."},
	{"speaker": "MULA SEM CABEÇA", "text": "..."},
]
const BOITATA_DIALOGUE: Array[Dictionary] = [
	{"speaker": "CAIPORA", "text": "Você nos traiu..."},
	{"speaker": "BOITATÁ", "text": "Vocês me abandonaram!"},
]
const CURUPIRA_DIALOGUE: Array[Dictionary] = [
	{"speaker": "CAIPORA",  "text": "ninguém te deixou..."},
	{"speaker": "CURUPIRA", "text": "isso pouco importa agora"},
]
const SACI_DIALOGUE: Array[Dictionary] = [
	{"speaker": "CAIPORA", "text": "Vou salvar nossa casa"},
	{"speaker": "SACI",    "text": "Não pertenço mais..."},
]

# ─── Exports ───────────────────────────────────────
@export var phase: int = 1

# ─── Onready ───────────────────────────────────────
@onready var _tilemap: TileMap = $TileMap
@onready var _caipora: Caipora = $Caipora
@onready var _enemies_container: Node2D = $Enemies
@onready var _objects_container: Node2D = $Objects

# ─── State ─────────────────────────────────────────
var _config: MapConfig
var _profile: Dictionary
var _map: GeneratedMap
var _map_enemies: Array[MapEnemy] = []
var _player_grid_pos: Vector2i = Vector2i.ZERO
var _locked: bool = false
var _key_node: Node2D = null
var _chest_node: Node2D = null
var _fog: FogOfWar

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	GameState.active_phase = phase
	_profile = _build_profile()
	_config = MapConfig.for_phase(phase)
	var reached: int = _profile["phase_reached_on_enter"]
	if reached > 0 and MetaProgression.phase_reached < reached:
		MetaProgression.phase_reached = reached
		MetaProgression.save_progress()
	_map = MapGenerator.new().generate(_config, GameState.map_seed_for_phase(phase))
	_setup_tilemap()
	_setup_player()
	_spawn_enemies()
	_spawn_objects()
	if _config.has_exit:
		_spawn_exit_marker()
	if _profile["has_fog"]:
		_spawn_fog()
	if _profile["ambient_life"]:
		_spawn_ambient_life()
	add_child(Atmosphere.new())

func _setup_player() -> void:
	var restoring := GameState.player_map_pos != Vector2i(-1, -1)
	var preferred := GameState.player_map_pos if restoring else _map.player_start
	# Na restauração (volta do combate) a posição é EXATA: o safe_spawn só vale para
	# a entrada fresca na fase — senão o jogador "saltaria" ao retornar do combate.
	var start: Vector2i = preferred
	if not restoring and _profile["safe_spawn"]:
		start = _find_safe_spawn(preferred)
	_player_grid_pos = start
	_caipora.tilemap = _tilemap
	_caipora.position = Vector2(start) * Constants.TILE_SIZE
	_caipora.move_finished.connect(_on_player_moved)
	_attach_aura()

func _attach_aura() -> void:
	match _profile["aura"]:
		Aura.TORCH:
			# Poça de luz fria (luar) que segue a Caipora — leitura na noite fechada.
			var torch := ForestLight.make(Color(0.88, 0.93, 1.0), 1.25, 1.6)
			_caipora.add_child(torch)
		Aura.FIRE:
			# Aura de fogo viva: luz quente + chama/brasas/fumaça.
			FireEffect.attach(_caipora, CAIPORA_AURA_OFFSET, CAIPORA_AURA_LIGHT_SCALE)

func _spawn_enemies() -> void:
	for def: Dictionary in _map.enemies:
		if def["id"] in GameState.defeated_enemy_ids:
			continue
		var spawn := Vector2i(def["x"], def["y"])
		# Restaura a posição salva no último combate; senão, o spawn do mapa gerado.
		var pos: Vector2i = GameState.map_enemy_positions.get(def["id"], spawn)
		var enemy := MapEnemy.new()
		_enemies_container.add_child(enemy)
		enemy.setup(def["id"], pos, def["boss"], def.get("boss_type", ""), spawn)
		_map_enemies.append(enemy)

func _spawn_objects() -> void:
	# Decoração temática (tipos determinísticos da paleta da fase).
	var deco_rng := RandomNumberGenerator.new()
	deco_rng.seed = GameState.map_seed_for_phase(phase) ^ 0xDEC0
	var palette: Array = _profile["deco_palette"]
	for pos: Vector2i in _map.decorations:
		var type: MapObject.Type = palette[deco_rng.randi_range(0, palette.size() - 1)]
		_make_object(type, pos)

	if _config.has_chest and not GameState.chest_opened and _map.chest_pos != Vector2i(-1, -1):
		_chest_node = _make_object(MapObject.Type.CHEST, _map.chest_pos)
	if _config.has_key and not GameState.has_key and _map.key_pos != Vector2i(-1, -1):
		_key_node = _make_object(MapObject.Type.KEY, _map.key_pos)

	# Hazards do mapa
	for y: int in _map.tiles.size():
		var row: Array = _map.tiles[y]
		for x: int in row.size():
			var ch: String = row[x]
			if ch == "R":
				_make_object(MapObject.Type.FIRE, Vector2i(x, y))
			elif ch == "S":
				_make_object(MapObject.Type.SPIKE, Vector2i(x, y))

func _spawn_exit_marker() -> void:
	var pos := _map.exit_pos
	if _profile["exit_marker"] == ExitMarker.SIMPLE:
		var marker := Sprite2D.new()
		marker.texture = preload("res://assets/sprites/tile_floor.png")
		marker.modulate = Constants.COLOR_EXIT
		marker.position = Vector2(pos) * Constants.TILE_SIZE
		add_child(marker)
	elif _profile["exit_marker"] == ExitMarker.PULSING:
		var center := Vector2(pos) * Constants.TILE_SIZE + Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE) * 0.5
		var marker := Sprite2D.new()
		marker.texture = preload("res://assets/sprites/tile_floor.png")
		marker.modulate = Constants.COLOR_EXIT
		marker.position = center - Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE) * 0.5
		add_child(marker)
		# Luz âmbar pulsante: marca a saída na escuridão sem texto.
		var light := ForestLight.make(Constants.COLOR_AMBER, 1.0, 1.0)
		light.position = center
		add_child(light)
		var tween := create_tween().set_loops()
		tween.tween_property(light, "energy", 1.4, 1.1).set_trans(Tween.TRANS_SINE)
		tween.tween_property(light, "energy", 0.7, 1.1).set_trans(Tween.TRANS_SINE)

func _spawn_ambient_life() -> void:
	# Vaga-lumes + insetos + neblina/esporos/god rays sobre a área interna.
	var t := Constants.TILE_SIZE
	var area := Rect2(t, t, (Constants.GRID_WIDTH - 2) * t, (Constants.GRID_HEIGHT - 2) * t)
	var life := AmbientLife.new()
	add_child(life)
	life.setup(area)
	var ambience := ForestAmbience.new()
	add_child(ambience)
	ambience.setup(area)

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
	if _profile["has_fog"]:
		_update_fog()

	# Saída (fases com tile 'E') → acampamento → próxima fase
	if _config.has_exit and new_grid_pos == _map.exit_pos:
		_locked = true
		# advance_phase_via_hub já zera a continuidade (jogador/inimigos no spawn na fase nova).
		GameState.advance_phase_via_hub(_profile["next_screen_on_exit"])
		return

	# Chave
	if _config.has_key and new_grid_pos == _map.key_pos and not GameState.has_key:
		GameState.has_key = true
		if _key_node != null:
			_key_node.visible = false

	# Baú
	if _config.has_chest and new_grid_pos == _map.chest_pos and not GameState.chest_opened:
		if GameState.has_key:
			_open_chest()

	# Colisão com inimigo
	for enemy in _map_enemies:
		if enemy.grid_pos == new_grid_pos:
			_trigger_combat(enemy)
			return

	# Hazard
	var ch := _map.char_at(new_grid_pos)
	if ch == "R" or ch == "S":
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
	var dmg: int = _profile["hazard_damage"]
	GameState.caipora_current_hp = maxi(0, GameState.caipora_current_hp - dmg)
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
	# Continuidade: congela onde o jogador e os inimigos sobreviventes estão AGORA,
	# para a exploração voltar idêntica depois do combate.
	GameState.player_map_pos = _player_grid_pos
	_snapshot_enemy_positions()
	GameState.active_map_enemy_id = enemy.enemy_id
	GameState.active_combat_is_boss = enemy.is_boss
	if enemy.is_boss:
		GameState.next_enemy_scene = _profile["boss_scene"]
		if (_profile["boss_dialogue"] as Array).is_empty():
			GameState.change_screen(_profile["arena_screen"])
		else:
			_show_boss_dialogue()
	else:
		GameState.next_enemy_scene = _profile["regular_scene"]
		GameState.change_screen(_profile["arena_screen"])

func _snapshot_enemy_positions() -> void:
	# Salva a posição atual de cada inimigo vivo (inclui o que será lutado — filtrado
	# por defeated_enemy_ids na volta). Sobrescreve o snapshot anterior por completo.
	GameState.map_enemy_positions.clear()
	for e in _map_enemies:
		GameState.map_enemy_positions[e.enemy_id] = e.grid_pos

func _show_boss_dialogue() -> void:
	var dlg: DialogueScreen = DIALOGUE_SCENE.instantiate()
	add_child(dlg)
	SignalBus.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
	dlg.start(_profile["boss_speaker"], _profile["boss_dialogue"], "CAIPORA",
		Constants.COLOR_DIALOGUE_CAIPORA, _profile["boss_color"])

func _on_dialogue_finished() -> void:
	GameState.change_screen(_profile["arena_screen"])

# ─── Spawn Helpers (spawn seguro: longe de fogo) ───
func _spawn_is_safe(pos: Vector2i) -> bool:
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
	# `enhanced` só afeta FIRE (luz + partículas). Ligado em fases de poucas fogueiras.
	var enhanced: bool = type == MapObject.Type.FIRE and _profile["enhance_fire"]
	obj.setup(type, grid_pos, enhanced)
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

# ─── Perfil de Apresentação/Rota por Fase ──────────
func _build_profile() -> Dictionary:
	match phase:
		2:
			return {
				"arena_screen": SignalBus.Screen.ARENA_PHASE2,
				"boss_scene": BOITATA_SCENE,
				"regular_scene": CACADOR_SCENE,
				"boss_dialogue": BOITATA_DIALOGUE,
				"boss_speaker": "BOITATÁ",
				"boss_color": Constants.COLOR_DIALOGUE_BOITATA,
				"next_screen_on_exit": SignalBus.Screen.EXPLORATION_PHASE3,
				"hazard_damage": Constants.FIRE_TILE_DAMAGE,
				"aura": Aura.NONE,
				"safe_spawn": false,
				"ambient_life": false,
				"phase_reached_on_enter": 2,
				"has_fog": false,
				"enhance_fire": true,
				"exit_marker": ExitMarker.SIMPLE,
				"deco_palette": DECO_FIRE,
			}
		3:
			return {
				"arena_screen": SignalBus.Screen.ARENA_PHASE3,
				"boss_scene": CURUPIRA_SCENE,
				"regular_scene": ASSOMBRACAO_SCENE,
				"boss_dialogue": CURUPIRA_DIALOGUE,
				"boss_speaker": "CURUPIRA",
				"boss_color": Constants.COLOR_DIALOGUE_CURUPIRA,
				"next_screen_on_exit": SignalBus.Screen.EXPLORATION_PHASE4,
				"hazard_damage": Constants.FIRE_TILE_DAMAGE,
				"aura": Aura.FIRE,
				"safe_spawn": true,
				"ambient_life": false,
				"phase_reached_on_enter": 0,
				"has_fog": true,
				"enhance_fire": false,
				"exit_marker": ExitMarker.NONE,
				"deco_palette": DECO_FOREST,
			}
		4:
			return {
				"arena_screen": SignalBus.Screen.ARENA_PHASE4,
				"boss_scene": SACI_SCENE,
				"regular_scene": ASSOMBRACAO_SCENE,
				"boss_dialogue": SACI_DIALOGUE,
				"boss_speaker": "SACI",
				"boss_color": Constants.COLOR_DIALOGUE_SACI,
				"next_screen_on_exit": SignalBus.Screen.ENDING,
				"hazard_damage": Constants.FIRE_TILE_DAMAGE,
				"aura": Aura.FIRE,
				"safe_spawn": true,
				"ambient_life": false,
				"phase_reached_on_enter": 0,
				"has_fog": false,
				"enhance_fire": false,
				"exit_marker": ExitMarker.NONE,
				"deco_palette": DECO_FIRE,
			}
		_:
			# Fase 1 (padrão): arena aberta, tocha, baú/chave, vida ambiente.
			# Boss: a Mula sem Cabeça (jato de fogo no lugar da cabeça).
			return {
				"arena_screen": SignalBus.Screen.ARENA,
				"boss_scene": MULA_SCENE,
				"regular_scene": null,
				"boss_dialogue": MULA_DIALOGUE,
				"boss_speaker": "MULA SEM CABEÇA",
				"boss_color": Constants.COLOR_DIALOGUE_MULA,
				"next_screen_on_exit": SignalBus.Screen.EXPLORATION_PHASE2,
				"hazard_damage": 1,
				"aura": Aura.TORCH,
				"safe_spawn": false,
				"ambient_life": true,
				"phase_reached_on_enter": 0,
				"has_fog": false,
				"enhance_fire": true,
				"exit_marker": ExitMarker.PULSING,
				"deco_palette": MapObject.DECO_TYPES,
			}
