extends Node2D

# Acampamento jogável (HUB entre fases). Mini-clareira cercada de mata: a Caipora anda,
# recupera HP cheio ao entrar e pisa no RASTRO (saída pulsante) para voltar à mata — à
# próxima exploração pendente (definida por GameState.advance_phase_via_hub) ou, vindo de
# uma derrota, ao começo de uma caçada nova (santuário).
#
# Etapa 1 da Fase 9: só grid + movimento + saída. As ERVAS no chão (compra ao pisar) e o
# HUD de fragmentos vêm nas Etapas 2/3. Reusa ao máximo a exploração: a MESMA entidade
# Caipora (movimento 4-direções, câmera, colisão por TileMap) e o marcador de saída
# pulsante (ForestLight + COLOR_EXIT). Nenhuma regra de combate ou economia é reimplementada.

const ForestLight := preload("res://scripts/exploration/forest_light.gd")

# Variantes de tile no atlas (espelha exploration_manager: source 0 = chão, source 1 = parede).
const FLOOR_VARIANTS := 4
const WALL_VARIANTS := 2

# Clareira do acampamento: retângulo de chão centrado no grid, cercado de parede. O grid
# mantém GRID_WIDTH×GRID_HEIGHT (a câmera da Caipora usa essas dimensões), então a mata em
# volta da clareira emoldura o respiro sem barras pretas.
const CLEARING_WIDTH := 14
const CLEARING_HEIGHT := 10

# ─── Onready ───────────────────────────────────────
@onready var _tilemap: TileMap = $TileMap
@onready var _caipora: Caipora = $Caipora
@onready var _objects: Node2D = $Objects

# ─── State ─────────────────────────────────────────
var _clearing: Rect2i
var _spawn_pos: Vector2i
var _exit_pos: Vector2i
var _locked: bool = false

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	# O acampamento é o único lugar onde a floresta não alcança: recupera HP cheio.
	GameState.heal_to_full()
	_compute_layout()
	_setup_tilemap()
	_setup_caipora()
	_spawn_exit_marker()

# Clareira centrada; spawn de um lado, rastro de saída do outro (mesma linha do meio).
func _compute_layout() -> void:
	var ox: int = (Constants.GRID_WIDTH - CLEARING_WIDTH) / 2
	var oy: int = (Constants.GRID_HEIGHT - CLEARING_HEIGHT) / 2
	_clearing = Rect2i(ox, oy, CLEARING_WIDTH, CLEARING_HEIGHT)
	var mid_y: int = oy + CLEARING_HEIGHT / 2
	_spawn_pos = Vector2i(ox + 1, mid_y)
	_exit_pos = Vector2i(ox + CLEARING_WIDTH - 2, mid_y)

func _is_floor(pos: Vector2i) -> bool:
	return _clearing.has_point(pos)

func _setup_caipora() -> void:
	_caipora.tilemap = _tilemap
	_caipora.position = Vector2(_spawn_pos) * Constants.TILE_SIZE
	_caipora.move_finished.connect(_on_caipora_moved)

# ─── Saída (rastro) ────────────────────────────────
func _on_caipora_moved(grid_pos: Vector2i) -> void:
	if _locked:
		return
	if grid_pos == _exit_pos:
		_trigger_exit()

func _trigger_exit() -> void:
	_locked = true
	var dest := _exit_destination()
	if not GameState.run_active:
		# Santuário pós-derrota: a run acabou — começa uma caçada nova.
		GameState.start_run()
	GameState.change_screen(dest)

## Destino do rastro: a exploração pendente (run em andamento, definida no avanço de fase)
## ou a Fase 1 (santuário pós-derrota, onde a run recomeça). Pura — o efeito colateral de
## iniciar a run fica em _trigger_exit.
func _exit_destination() -> SignalBus.Screen:
	return GameState.pending_exploration if GameState.run_active else SignalBus.Screen.EXPLORATION

# ─── Marcador de saída (reuso do pulsante da exploração) ───
func _spawn_exit_marker() -> void:
	var half := Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE) * 0.5
	var center := Vector2(_exit_pos) * Constants.TILE_SIZE + half
	var marker := Sprite2D.new()
	marker.texture = preload("res://assets/sprites/tile_floor.png")
	marker.modulate = Constants.COLOR_EXIT
	marker.position = Vector2(_exit_pos) * Constants.TILE_SIZE
	_objects.add_child(marker)
	# Luz âmbar pulsante: marca a saída na penumbra sem texto (mesma leitura da exploração).
	var light := ForestLight.make(Constants.COLOR_AMBER, 1.0, 1.0)
	light.position = center
	_objects.add_child(light)
	var tween := create_tween().set_loops()
	tween.tween_property(light, "energy", 1.4, 1.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(light, "energy", 0.7, 1.1).set_trans(Tween.TRANS_SINE)

# ─── TileMap (mesmo tileset/atlas da exploração) ───
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

# Source 0 = chão (andável) na clareira; source 1 = parede (bloqueia) na mata em volta.
# A Caipora colide nativamente: _would_collide() trata source_id == 1 como parede.
func _paint_map() -> void:
	for y: int in Constants.GRID_HEIGHT:
		for x: int in Constants.GRID_WIDTH:
			var pos := Vector2i(x, y)
			if _is_floor(pos):
				var fv: int = (x * 7 + y * 13) % FLOOR_VARIANTS
				_tilemap.set_cell(0, pos, 0, Vector2i(fv, 0))
			else:
				var wv: int = (x * 5 + y * 11) % WALL_VARIANTS
				_tilemap.set_cell(0, pos, 1, Vector2i(wv, 0))
