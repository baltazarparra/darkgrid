class_name TitleGround
extends Node2D

## Crista de chão em primeiro plano da abertura — a silhueta sólida onde a Caipora
## caminha. Borda superior levemente irregular (determinística), preenchida até a
## base do viewport. Expõe `crest_y` para o TitleWalker assentar os pés.

# ─── Exports ───────────────────────────────────────
@export var ground_color: Color = Constants.COLOR_BARK_DARK
@export var crest_y: float = 620.0
@export var roughness: float = 12.0
@export var layer_z: int = -50
@export var rng_seed: int = 7

# ─── Constants ─────────────────────────────────────
const SEGMENTS: int = 32

# ─── State ─────────────────────────────────────────
var _vp_w: float = 1280.0
var _vp_h: float = 720.0
var _eff_crest_y: float = 0.0
var _crest: PackedVector2Array

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	var vp := get_viewport().get_visible_rect().size
	_vp_w = vp.x
	_vp_h = vp.y
	_eff_crest_y = crest_y / 720.0 * _vp_h
	z_index = layer_z
	_generate()

# ─── Drawing ───────────────────────────────────────
func _draw() -> void:
	draw_colored_polygon(_crest, ground_color)

# ─── Private helpers ───────────────────────────────
func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var pts: PackedVector2Array = []
	pts.append(Vector2(0, _vp_h))
	for i: int in SEGMENTS + 1:
		var x: float = _vp_w * i / float(SEGMENTS)
		var y: float = _eff_crest_y + rng.randf_range(-roughness, roughness)
		pts.append(Vector2(x, y))
	pts.append(Vector2(_vp_w, _vp_h))
	_crest = pts
	queue_redraw()
