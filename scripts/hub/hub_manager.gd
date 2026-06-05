extends Node2D

# Acampamento jogável (HUB entre fases). Mini-clareira cercada de mata onde a floresta não
# alcança: fogueira baixa, cachimbo, ervas no chão ao redor do fogo. A Caipora anda, recupera
# HP cheio ao entrar, fuma as ervas que pode pagar (compra ao pisar) e pisa no RASTRO (saída
# pulsante) para voltar à mata — à próxima exploração pendente (advance_phase_via_hub) ou,
# vindo de uma derrota, ao começo de uma caçada nova (santuário).
#
# Reusa ao máximo a exploração: a MESMA entidade Caipora (movimento/câmera/colisão por
# TileMap), o marcador de saída pulsante (ForestLight + COLOR_EXIT), a fogueira (MapObject
# FIRE), a vida ambiente (AmbientLife/ForestAmbience) e o color-grade (Atmosphere). Nenhuma
# regra de combate ou economia é reimplementada — purchase_upgrade é a fonte única.

const ForestLight := preload("res://scripts/exploration/forest_light.gd")
const HubPickup := preload("res://scripts/hub/hub_pickup.gd")
const MapObject := preload("res://scripts/exploration/map_object.gd")

# Identidade do acampamento.
const CACHIMBO_TEXTURE := preload("res://assets/sprites/cachimbo.png")

# Variantes de tile no atlas (espelha exploration_manager: source 0 = chão, source 1 = parede).
const FLOOR_VARIANTS := 4
const WALL_VARIANTS := 2

# Clareira do acampamento: retângulo de chão centrado no grid, cercado de parede. O grid
# mantém GRID_WIDTH×GRID_HEIGHT (a câmera da Caipora usa essas dimensões), então a mata em
# volta da clareira emoldura o respiro sem barras pretas.
const CLEARING_WIDTH := 14
const CLEARING_HEIGHT := 10

# Disposição das ervas: trilha da FÚRIA acima da linha do meio, CURA abaixo — fileiras
# diante do fogo, fora do caminho direto spawn→saída (o jogador escolhe o que pisar).
const ERVA_ROW_OFFSET := 2            # distância vertical da linha do meio
const ERVA_FIRST_COL := 3            # 1ª coluna de erva (a partir da borda da clareira)
const ERVA_COL_STEP := 2             # espaçamento horizontal entre ervas

# ─── Onready ───────────────────────────────────────
@onready var _tilemap: TileMap = $TileMap
@onready var _caipora: Caipora = $Caipora
@onready var _objects: Node2D = $Objects
@onready var _hud: HubHud = $HubHud
@onready var _sfx: SfxSystem = $SfxSystem

# ─── State ─────────────────────────────────────────
var _clearing: Rect2i
var _spawn_pos: Vector2i
var _exit_pos: Vector2i
var _fire_pos: Vector2i
var _locked: bool = false

# Ervas no chão: grid_pos → HubPickup. Pisar numa entrada tenta a compra.
var _ervas: Dictionary = {}

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	# O acampamento é o único lugar onde a floresta não alcança: recupera HP cheio.
	GameState.heal_to_full()
	_compute_layout()
	_setup_tilemap()
	_setup_caipora()
	_spawn_exit_marker()
	_spawn_ervas()
	_spawn_camp_identity()

# Clareira centrada; spawn de um lado, rastro de saída do outro (mesma linha do meio). A
# fogueira fica no centro (vira parede: bloqueia o atalho reto, então o jogador contorna
# pelas fileiras de ervas — exatamente o "andar entre as ervas ao redor do fogo").
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

# ─── Ervas no chão (compra ao pisar) ───────────────
# Aparecem todas as ervas compráveis da fase alcançada: phase_reached >= phase, requires
# atendido (ou vazio) e ainda não comprada — o MESMO gate do hub de cards. O conjunto é
# montado na ENTRADA; comprar a 'forca' só libera 'forca_2' na PRÓXIMA visita (documentado
# no PRD da Fase 9). purchase_upgrade continua a fonte única de custo/requires/persistência.
func _spawn_ervas() -> void:
	var mid_y: int = _spawn_pos.y
	_place_erva_row(_available_keys(MetaProgression.FURIA_KEYS), mid_y - ERVA_ROW_OFFSET)
	_place_erva_row(_available_keys(MetaProgression.CURA_KEYS), mid_y + ERVA_ROW_OFFSET)
	_refresh_affordability()

func _available_keys(keys: Array) -> Array:
	var out: Array = []
	for key: String in keys:
		var def: Dictionary = MetaProgression.UPGRADE_DEFS[key]
		if MetaProgression.phase_reached < int(def.get("phase", 1)):
			continue
		var req: String = def.get("requires", "")
		if req != "" and MetaProgression.get_upgrade_level(req) < 1:
			continue
		if MetaProgression.get_upgrade_level(key) >= 1:
			continue
		out.append(key)
	return out

func _place_erva_row(keys: Array, row_y: int) -> void:
	var x: int = _clearing.position.x + ERVA_FIRST_COL
	for key: String in keys:
		var pos := Vector2i(x, row_y)
		var pickup := HubPickup.new()
		_objects.add_child(pickup)
		pickup.setup(key, pos)
		_ervas[pos] = pickup
		x += ERVA_COL_STEP

# Re-avalia o brilho de cada erva restante (comprar uma pode ter esvaziado o bolso).
func _refresh_affordability() -> void:
	for pos: Vector2i in _ervas:
		var pickup: HubPickup = _ervas[pos]
		pickup.set_affordable(MetaProgression.fragments >= pickup.cost)

func _try_buy(grid_pos: Vector2i) -> void:
	var pickup: HubPickup = _ervas[grid_pos]
	# purchase_upgrade valida requires/custo/max_level e persiste o save. Como o conjunto
	# já passou o gate de requires na entrada, a única recusa aqui é fragmento insuficiente.
	if MetaProgression.purchase_upgrade(pickup.key):
		_ervas.erase(grid_pos)
		pickup.consume()
		_hud.refresh()
		_refresh_affordability()
		_sfx.play(_sfx.timing_perfect_sound, -3.0)  # "fumar": chiado da recompensa
		_spawn_floating_cost(grid_pos, pickup.cost)
	else:
		pickup.deny()
		_sfx.play(_sfx.ui_click_sound, -8.0)        # insuficiente: clique seco e baixo

# Número flutuante "−custo" subindo do tile da erva (world-space).
func _spawn_floating_cost(grid_pos: Vector2i, cost: int) -> void:
	var label := Label.new()
	label.text = "-%d" % cost
	label.add_theme_font_size_override("font_size", Constants.FONT_SM)
	label.add_theme_color_override("font_color", Constants.COLOR_AMBER)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(Constants.TILE_SIZE, 0)
	label.position = Vector2(grid_pos) * Constants.TILE_SIZE
	label.z_index = 5
	_objects.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 28.0, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9)
	tween.chain().tween_callback(label.queue_free)

# ─── Saída (rastro) ────────────────────────────────
func _on_caipora_moved(grid_pos: Vector2i) -> void:
	if _locked:
		return
	if _ervas.has(grid_pos):
		_try_buy(grid_pos)
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
