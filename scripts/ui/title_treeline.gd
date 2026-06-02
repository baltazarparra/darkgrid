class_name TitleTreeline
extends Node2D

## Camada de silhueta de árvores mortas para a abertura ("Horizonte Infernal").
## Faz scroll horizontal com wrap sem costura (desenha duas cópias lado a lado),
## criando parallax quando instanciada em velocidades diferentes (FAR lenta, MID
## rápida). Reusa o vocabulário procedural de MapObject._draw_dead_tree. Puramente
## decorativo — sem colisão, sem input.

# ─── Exports ───────────────────────────────────────
@export var scroll_speed: float = 8.0
@export var silhouette_color: Color = Constants.COLOR_BARK_DARK
@export var base_y: float = 560.0
@export var tree_count: int = 10
@export var tree_scale: float = 2.0
@export var layer_z: int = -80
@export var rng_seed: int = 1

# ─── Constants ─────────────────────────────────────
const VIEWPORT_W: float = 1280.0
const VIEWPORT_H: float = 720.0

# ─── State ─────────────────────────────────────────
var _offset: float = 0.0
var _trees: Array[Dictionary] = []

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	z_index = layer_z
	_generate_trees()

func _process(delta: float) -> void:
	_offset += scroll_speed * delta
	if _offset >= VIEWPORT_W:
		_offset -= VIEWPORT_W
	position.x = -_offset
	queue_redraw()

# ─── Drawing ───────────────────────────────────────
func _draw() -> void:
	_draw_strip(0.0)
	_draw_strip(VIEWPORT_W)

func _draw_strip(ox: float) -> void:
	# Massa sólida do chão/cordilheira (recorta contra o fogo).
	draw_rect(Rect2(ox, base_y, VIEWPORT_W, VIEWPORT_H - base_y), silhouette_color)
	for t: Dictionary in _trees:
		_draw_tree(ox + t.x, base_y, t.height, t.scale)

func _draw_tree(tx: float, gy: float, hfac: float, sc: float) -> void:
	# Altura cresce com o "depth scale" para a treeline MID dominar sobre a FAR.
	var trunk_h: float = 60.0 * hfac * (0.7 + sc * 0.22)
	var trunk_w: float = 3.0 * sc
	var top: float = gy - trunk_h
	draw_rect(Rect2(tx - trunk_w * 0.5, top, trunk_w, trunk_h), silhouette_color)
	# Galhos secos retorcidos (silhueta — cor única).
	var branches: Array = [
		[Vector2(tx, top + 6), Vector2(tx - 16 * sc, top - 10 * sc)],
		[Vector2(tx, top + 2), Vector2(tx + 14 * sc, top - 14 * sc)],
		[Vector2(tx, top + 14), Vector2(tx + 10 * sc, top + 2)],
		[Vector2(tx, top + 10), Vector2(tx - 12 * sc, top - 4 * sc)],
	]
	for b: Array in branches:
		draw_line(b[0], b[1], silhouette_color, 2.0 * sc)

# ─── Private helpers ───────────────────────────────
func _generate_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	_trees.clear()
	for i: int in tree_count:
		_trees.append({
			"x": rng.randf() * VIEWPORT_W,
			"height": rng.randf_range(0.6, 1.3),
			"scale": tree_scale * rng.randf_range(0.8, 1.3),
		})
