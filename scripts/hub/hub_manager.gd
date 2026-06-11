extends Node2D

# Acampamento jogável (HUB entre fases). Mini-clareira cercada de mata onde a floresta não
# alcança: fogueira baixa, cachimbo, e a interface de aprimoramentos (HubShop) por cima — cards
# clicáveis das ervas que a Caipora pode fumar, numa faixa no topo. A Caipora anda, recupera HP cheio ao
# entrar e pisa no RASTRO (saída pulsante) para voltar à mata — à próxima exploração pendente
# (advance_phase_via_hub) ou, vindo de uma derrota, ao começo de uma caçada nova (santuário).
#
# Reusa ao máximo a exploração: a MESMA entidade Caipora (movimento/câmera/colisão por
# TileMap), o marcador de saída pulsante (ForestLight + COLOR_EXIT), a fogueira (MapObject
# FIRE), a vida ambiente (AmbientLife/ForestAmbience) e o color-grade (Atmosphere). A compra
# vive no HubShop (purchase_upgrade é a fonte única); aqui só tocamos o SFX da compra.

const ForestLight := preload("res://scripts/exploration/forest_light.gd")
const MapObject := preload("res://scripts/exploration/map_object.gd")
const HubExitBeaconScript := preload("res://scripts/hub/exit_beacon.gd")

# Identidade do acampamento.
const CACHIMBO_TEXTURE := preload("res://assets/sprites/cachimbo.png")

# Variantes de tile no atlas (espelha exploration_manager: source 0 = chão, source 1 = parede).
const FLOOR_VARIANTS := 4
const WALL_VARIANTS := 2

# Clareira do acampamento: retângulo de chão centrado no grid, cercado de parede. O grid
# mantém GRID_WIDTH×GRID_HEIGHT (a câmera da Caipora usa essas dimensões), então a mata em
# volta da clareira emoldura o respiro sem barras pretas.
const CLEARING_WIDTH := 16
const CLEARING_HEIGHT := 12

# ─── Onready ───────────────────────────────────────
@onready var _tilemap: TileMap = $TileMap
@onready var _caipora: Caipora = $Caipora
@onready var _objects: Node2D = $Objects
@onready var _shop: HubShop = $HubShop
@onready var _sfx: SfxSystem = $SfxSystem

# ─── State ─────────────────────────────────────────
var _clearing: Rect2i
var _spawn_pos: Vector2i
var _exit_pos: Vector2i
var _fire_pos: Vector2i
var _locked: bool = false

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	# O acampamento é o único lugar onde a floresta não alcança: recupera HP cheio.
	GameState.heal_to_full()
	_compute_layout()
	_setup_tilemap()
	_setup_caipora()
	_spawn_exit_marker()
	_spawn_exit_beacon()
	_spawn_camp_identity()
	_spawn_spirits()
	# O HubShop (filho) já está montado no seu _ready; aqui só ligamos o SFX da compra.
	_shop.purchased.connect(_on_purchased)
	_shop.denied.connect(_on_denied)

# Clareira centrada; spawn de um lado, rastro de saída do outro (mesma linha do meio). A
# fogueira fica no centro (vira parede: bloqueia o atalho reto, então o jogador contorna ao
# voltar para o rastro). Os cards de aprimoramento ficam por cima, no HubShop (screen-space).
func _compute_layout() -> void:
	var ox: int = (Constants.GRID_WIDTH - CLEARING_WIDTH) / 2
	var oy: int = (Constants.GRID_HEIGHT - CLEARING_HEIGHT) / 2
	_clearing = Rect2i(ox, oy, CLEARING_WIDTH, CLEARING_HEIGHT)
	var mid_y: int = oy + CLEARING_HEIGHT / 2
	_spawn_pos = Vector2i(ox + 1, mid_y)
	_exit_pos = Vector2i(ox + CLEARING_WIDTH - 2, mid_y)
	_fire_pos = Vector2i(ox + CLEARING_WIDTH / 2, mid_y)

func _is_floor(pos: Vector2i) -> bool:
	return _clearing.has_point(pos)

func _setup_caipora() -> void:
	_caipora.tilemap = _tilemap
	_caipora.position = Vector2(_spawn_pos) * Constants.TILE_SIZE
	_caipora.move_finished.connect(_on_caipora_moved)

# ─── SFX da compra (dono do SfxSystem) ─────────────
## "Fumar a erva": chocalho da colheita e, um tempo de tragada depois, o sopro no
## cachimbo. Timer da cena (morre com ela); fallback preserva o feedback antigo.
const PIPE_SMOKE_DELAY: float = 0.25

func _on_purchased(_key: String) -> void:
	if not _sfx.play_named("herb_pickup"):
		_sfx.play(_sfx.timing_perfect_sound, -3.0)
		return
	get_tree().create_timer(PIPE_SMOKE_DELAY).timeout.connect(
		func() -> void: _sfx.play_named("pipe_smoke"))

func _on_denied(_key: String) -> void:
	_sfx.play(_sfx.ui_click_sound, -8.0)          # insuficiente: clique seco e baixo

# ─── Saída (rastro) ────────────────────────────────
func _on_caipora_moved(grid_pos: Vector2i) -> void:
	if _locked:
		return
	# move_finished = movimento confirmado; o acampamento é chão de mata.
	_sfx.play_named("step_grass", Constants.STEP_VOLUME_DB)
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

# ─── Marcador de saída (boca de toca coberta de folhas) ───
func _spawn_exit_marker() -> void:
	var half := Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE) * 0.5
	var center := Vector2(_exit_pos) * Constants.TILE_SIZE + half
	# Boca de toca com folhas (MapObject.BURROW): simboliza a saída pra mata melhor que o
	# tile âmbar — e centra no tile (o Sprite2D antigo ficava meio tile fora do lugar).
	var burrow := MapObject.new()
	_objects.add_child(burrow)
	burrow.setup(MapObject.Type.BURROW, _exit_pos)
	# Luz âmbar pulsante: marca a saída na penumbra sem texto (mesma leitura da exploração).
	var light := ForestLight.make(Constants.COLOR_AMBER, 1.0, 1.8)
	light.position = center
	_objects.add_child(light)
	var tween := create_tween().set_loops()
	tween.tween_property(light, "energy", 2.0, 1.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(light, "energy", 0.9, 1.3).set_trans(Tween.TRANS_SINE)

# Seta de borda que aponta pro rastro enquanto ele está fora do quadro (em retrato a saída
# nasce fora da tela, à direita). Numa CanvasLayer acima do mundo e abaixo do HubShop (layer 10),
# pra ficar visível na metade de baixo livre sem cobrir os cards nem o cabeçalho.
func _spawn_exit_beacon() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)
	var half := Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE) * 0.5
	var beacon: Control = HubExitBeaconScript.new()
	beacon.setup(Vector2(_exit_pos) * Constants.TILE_SIZE + half)
	layer.add_child(beacon)

# ─── Identidade do acampamento ─────────────────────
# Fogueira no centro, cachimbo ao pé do fogo, vida ambiente sobre a clareira e o color-grade
# da Atmosphere — o único respiro entre as caçadas. Tudo reusado da exploração.
func _spawn_camp_identity() -> void:
	# Fogueira viva (chama desenhada + luz + brasas/fumaça), igual às fases de poucas fogueiras.
	var fire := MapObject.new()
	_objects.add_child(fire)
	fire.setup(MapObject.Type.FIRE, _fire_pos, true)

	# Cachimbo descansando no chão, ao lado do fogo (decoração — a Caipora passa por cima).
	var cachimbo := Sprite2D.new()
	cachimbo.texture = CACHIMBO_TEXTURE
	cachimbo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cachimbo.position = Vector2(_fire_pos + Vector2i(1, 0)) * Constants.TILE_SIZE \
		+ Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE) * 0.5
	cachimbo.scale = Vector2(0.5, 0.5)
	cachimbo.z_index = -1
	_objects.add_child(cachimbo)

	# Vaga-lumes/insetos + neblina/esporos sobre a clareira (área interna).
	var t := Constants.TILE_SIZE
	var bounds := Rect2(Vector2(_clearing.position) * t, Vector2(_clearing.size) * t)
	var life := AmbientLife.new()
	add_child(life)
	life.setup(bounds)
	var ambience := ForestAmbience.new()
	add_child(ambience)
	ambience.setup(bounds)

	# Vinheta/grão/color-grade: costura o acampamento ao mesmo mundo das fases.
	add_child(Atmosphere.new())

# ─── Santuário dos Encantados ──────────────────────
# Os encantados libertados (MetaProgression.freed_bosses) vivem aqui: presenças em
# repouso (CampSpirit) na moldura de mata ao redor da clareira — celas não-caminháveis,
# walkability intocada. O visual de cada espírito é data-driven em CampSpirit.DEFS;
# aqui mora só o layout (a cela de cada um no acampamento).
func _spawn_spirits() -> void:
	var half := Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE) * 0.5
	for spirit_phase: int in MetaProgression.freed_bosses:
		var spirit := CampSpirit.new()
		_objects.add_child(spirit)
		if not spirit.setup(spirit_phase):
			spirit.queue_free()
			continue
		spirit.position = Vector2(_spirit_anchor(spirit_phase)) * Constants.TILE_SIZE + half

# Cela de cada espírito na moldura de mata: Mula ao norte (perto do fogo), Boitatá
# enrodilhado a leste, Curupira de sentinela a sudoeste, Saci fumando a sudeste.
# Derivado de _clearing — acompanha qualquer mudança de layout da clareira.
func _spirit_anchor(spirit_phase: int) -> Vector2i:
	match spirit_phase:
		1: return Vector2i(_clearing.position.x + 7, _clearing.position.y - 1)
		2: return Vector2i(_clearing.end.x, _clearing.position.y + 2)
		3: return Vector2i(_clearing.position.x + 2, _clearing.end.y)
		4: return Vector2i(_clearing.end.x - 3, _clearing.end.y)
	return _clearing.position

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
			# A fogueira no centro bloqueia (parede sob o fogo); o resto da clareira é chão.
			if _is_floor(pos) and pos != _fire_pos:
				var fv: int = (x * 7 + y * 13) % FLOOR_VARIANTS
				_tilemap.set_cell(0, pos, 0, Vector2i(fv, 0))
			else:
				var wv: int = (x * 5 + y * 11) % WALL_VARIANTS
				_tilemap.set_cell(0, pos, 1, Vector2i(wv, 0))
