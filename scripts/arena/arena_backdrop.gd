class_name ArenaBackdrop
extends Node2D

## Palco da arena: céu, treelines em planos, banda de chão tileada e props por
## fase — tudo em world space atrás dos atores, dimensionado ao redor do STAGE
## do ArenaManager (centro 320,225). Construído 100% por código (padrão
## Atmosphere.new()): o ArenaManager só instancia; a fase vem de
## GameState.active_phase.
##
## O terço central do stage fica de baixo contraste de propósito: é onde as
## bolhas de timing e os atores vivem — o palco emoldura, não compete.

# Geometria do palco (coordenadas de mundo, derivadas do STAGE 560×340 @ 320,225).
# As faixas extrapolam o stage porque em retrato a câmera revela muito além dele.
const HORIZON_Y: float = 150.0
const SKY_TOP: float = -600.0
const FLOOR_BOTTOM: float = 598.0
const STRIP_X: float = -120.0
const STRIP_W: float = 840.0
const TILE: int = 32

# Planos de treeline: FAR baixa e densa atrás, MID alta e esparsa na frente.
const FAR_TREES: int = 13
const MID_TREES: int = 8
const TREE_BAND_H: float = 36.0

const FLOOR_VARIANTS: int = 4
const WALL_VARIANTS: int = 2
# Chão some na escuridão: brilho cai com a distância do horizonte (longe = escuro)
# e as últimas linhas desvanecem em alpha para fundir com o vazio abaixo.
const FLOOR_NEAR_BRIGHT: float = 1.0
const FLOOR_FAR_BRIGHT: float = 0.22

# Estilo por fase. sky usa alpha parcial para o DoomFire (CanvasLayer atrás)
# respirar através — P2/P4 (mata queimada) deixam o fogo vazar mais.
const PHASE_STYLE: Dictionary = {
	1: {
		"sky": Color(0.030, 0.040, 0.065, 0.85),
		"far": Color(0.050, 0.034, 0.016),
		"mid": Color(0.095, 0.060, 0.022),
		"floor": "res://assets/sprites/tile_floor.png",
		"floor_gain": 1.0,
		"church": false,
	},
	2: {
		"sky": Color(0.085, 0.018, 0.0, 0.38),
		"far": Color(0.075, 0.020, 0.004),
		"mid": Color(0.120, 0.040, 0.010),
		"floor": "res://assets/sprites/tile_floor.png",
		"floor_gain": 1.15,
		"church": false,
	},
	3: {
		"sky": Color(0.018, 0.045, 0.028, 0.90),
		"far": Color(0.028, 0.062, 0.036),
		"mid": Color(0.055, 0.105, 0.055),
		"floor": "res://assets/sprites/tile_floor.png",
		"floor_gain": 1.7,
		"church": false,
	},
	4: {
		"sky": Color(0.055, 0.012, 0.010, 0.52),
		"far": Color(0.065, 0.014, 0.010),
		"mid": Color(0.105, 0.028, 0.018),
		"floor": "res://assets/sprites/tile_floor.png",
		"floor_gain": 1.55,
		"church": false,
	},
	5: {
		"sky": Color(0.040, 0.042, 0.058, 0.92),
		"far": Color(0.0, 0.0, 0.0),
		"mid": Color(0.0, 0.0, 0.0),
		"floor": "res://assets/sprites/tile_floor_church.png",
		"floor_gain": 1.2,
		"church": true,
	},
}

var _floor_tex: Texture2D
var _wall_tex: Texture2D
var _style: Dictionary

func _ready() -> void:
	z_index = -20
	_style = PHASE_STYLE.get(GameState.active_phase, PHASE_STYLE[1])
	_floor_tex = load(_style["floor"])
	if _style["church"]:
		_wall_tex = load("res://assets/sprites/tile_wall_church.png")
	else:
		_add_treeline(_style["far"], FAR_TREES, 1.5, 0.66, HORIZON_Y - 4.0, 41)
		_add_treeline(_style["mid"], MID_TREES, 2.3, 1.0, HORIZON_Y + 8.0, 97)
	queue_redraw()

func _add_treeline(color: Color, count: int, scale_f: float, height_f: float,
		base_world_y: float, seed_v: int) -> void:
	var line := TitleTreeline.new()
	line.static_bounds = Rect2(0.0, 0.0, STRIP_W, height_f * 110.0 + TREE_BAND_H)
	line.base_y = height_f * 110.0
	line.scroll_speed = 0.0
	line.silhouette_color = color
	line.tree_count = count
	line.tree_scale = scale_f
	line.rng_seed = seed_v
	# z relativo 0: filhos desenham depois do _draw do pai (céu/chão) — as copas
	# ficam sobre o céu e a massa da base ancora as árvores sobre o chão.
	line.layer_z = 0
	line.position = Vector2(STRIP_X, base_world_y - height_f * 110.0)
	add_child(line)

func _draw() -> void:
	draw_rect(
		Rect2(STRIP_X, SKY_TOP, STRIP_W, HORIZON_Y - SKY_TOP),
		_style["sky"])
	_draw_floor()
	if _style["church"]:
		_draw_church()

func _draw_floor() -> void:
	var rows: int = int((FLOOR_BOTTOM - HORIZON_Y) / float(TILE))
	var cols: int = int(STRIP_W / float(TILE))
	for row: int in rows:
		var y: float = HORIZON_Y + row * TILE
		# Longe (horizonte) escuro, perto claro.
		var depth: float = 1.0 - float(row) / float(maxi(rows - 1, 1))
		var gain: float = _style["floor_gain"]
		var bright: float = lerpf(FLOOR_NEAR_BRIGHT, FLOOR_FAR_BRIGHT, pow(depth, 1.3)) * gain
		# As últimas 4 linhas desvanecem em alpha — o chão funde com o vazio
		# abaixo em vez de terminar numa aresta dura.
		var fade: float = 1.0
		var from_end: int = rows - 1 - row
		if from_end < 4:
			fade = [0.10, 0.28, 0.52, 0.78][from_end]
		var tint := Color(bright, bright, bright, fade)
		for col: int in cols:
			var variant: int = (col * 31 + row * 17) % FLOOR_VARIANTS
			draw_texture_rect_region(
				_floor_tex,
				Rect2(STRIP_X + col * TILE, y, TILE, TILE),
				Rect2(variant * TILE, 0, TILE, TILE),
				tint)

func _draw_church() -> void:
	# Parede de fundo da nave: duas fiadas de taipa acima do horizonte, escurecendo
	# para cima (a abóbada some na treva).
	for row: int in 2:
		var y: float = HORIZON_Y - (row + 1) * TILE
		var bright: float = 0.62 - row * 0.30
		for col: int in int(STRIP_W / float(TILE)):
			var variant: int = (col * 13 + row * 7) % WALL_VARIANTS
			draw_texture_rect_region(
				_wall_tex,
				Rect2(STRIP_X + col * TILE, y, TILE, TILE),
				Rect2(variant * TILE, 0, TILE, TILE),
				Color(bright, bright, bright))
	# Cruz torta sobre o altar, no eixo central acima da ação (vocabulário do
	# MapObject._draw_cross, ampliado 2x — silhueta litúrgica, baixo contraste).
	var cx: float = 320.0
	var cy: float = HORIZON_Y - 34.0
	var wood := Constants.COLOR_WOOD_DARK
	var gold := Constants.COLOR_GOLD_DARK
	draw_rect(Rect2(cx - 4.0, cy - 24.0, 8.0, 48.0), wood)
	draw_rect(Rect2(cx - 14.0, cy - 12.0, 28.0, 8.0), wood)
	draw_rect(Rect2(cx - 2.0, cy - 24.0, 4.0, 48.0), gold)
	draw_rect(Rect2(cx - 14.0, cy - 10.0, 28.0, 2.0), gold)
	# Altar: bloco de pedra sob a cruz, na linha do horizonte.
	draw_rect(Rect2(cx - 30.0, HORIZON_Y - 12.0, 60.0, 12.0), Constants.COLOR_STONE_DARK)
	draw_rect(Rect2(cx - 30.0, HORIZON_Y - 12.0, 60.0, 3.0), Constants.COLOR_STONE)
	# Bancos quebrados flanqueando a nave (fora do terço central da ação),
	# vocabulário do MapObject._draw_pew ampliado.
	for pew_y: float in [210.0, 268.0, 326.0]:
		_draw_pew_silhouette(28.0, pew_y)
		_draw_pew_silhouette(612.0, pew_y)

func _draw_pew_silhouette(cx: float, cy: float) -> void:
	var wood := Constants.COLOR_WOOD
	var wood_dark := Constants.COLOR_WOOD_DARK
	draw_rect(Rect2(cx - 36.0, cy + 4.0, 72.0, 8.0), wood_dark)   # assento
	draw_rect(Rect2(cx - 36.0, cy + 4.0, 72.0, 3.0), wood)
	draw_rect(Rect2(cx - 36.0, cy - 12.0, 72.0, 6.0), wood_dark)  # encosto
	draw_rect(Rect2(cx - 36.0, cy - 12.0, 72.0, 2.0), wood)
	draw_rect(Rect2(cx - 33.0, cy + 10.0, 6.0, 12.0), wood_dark)  # pernas
	draw_rect(Rect2(cx + 25.0, cy + 10.0, 6.0, 12.0), wood_dark)
	draw_rect(Rect2(cx - 33.0, cy - 12.0, 4.0, 16.0), wood_dark)  # suportes
	draw_rect(Rect2(cx + 27.0, cy - 12.0, 4.0, 16.0), wood_dark)
