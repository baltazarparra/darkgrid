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
const VIEWPORT_W: float = 1280.0
const VIEWPORT_H: float = 720.0
const SEGMENTS: int = 32

# ─── State ─────────────────────────────────────────
var _crest: PackedVector2Array

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
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
	pts.append(Vector2(0, VIEWPORT_H))
	for i: int in SEGMENTS + 1:
		var x: float = VIEWPORT_W * i / float(SEGMENTS)
		var y: float = crest_y + rng.randf_range(-roughness, roughness)
		pts.append(Vector2(x, y))
	pts.append(Vector2(VIEWPORT_W, VIEWPORT_H))
	_crest = pts
	queue_redraw()
