class_name MapObject
extends Node2D

enum Type { CHEST, KEY, FIRE, SPIKE, DEAD_TREE, BONES, MOSS, BLOOD_POOL, ROCK }

const T: int = Constants.TILE_SIZE  # 32

# Decorações puramente visuais (não-bloqueantes), renderizadas atrás das entidades.
const DECO_TYPES := [Type.DEAD_TREE, Type.BONES, Type.MOSS, Type.BLOOD_POOL, Type.ROCK]

var _type: Type

# ─── Public API ────────────────────────────────────
func setup(type: Type, grid_pos: Vector2i) -> void:
	_type = type
	position = Vector2(grid_pos) * T
	if type in DECO_TYPES:
		z_index = -1  # ambientação fica embaixo de jogador/inimigos/baú
	queue_redraw()

# ─── Drawing ───────────────────────────────────────
func _draw() -> void:
	var cx: float = T / 2.0
	var cy: float = T / 2.0
	match _type:
		Type.CHEST:      _draw_chest(cx, cy)
		Type.KEY:        _draw_key(cx, cy)
		Type.FIRE:       _draw_fire(cx, cy)
		Type.SPIKE:      _draw_spike(cx, cy)
		Type.DEAD_TREE:  _draw_dead_tree(cx, cy)
		Type.BONES:      _draw_bones(cx, cy)
		Type.MOSS:       _draw_moss(cx, cy)
		Type.BLOOD_POOL: _draw_blood_pool(cx, cy)
		Type.ROCK:       _draw_rock(cx, cy)

func _draw_fire(cx: float, cy: float) -> void:
	draw_circle(Vector2(cx, cy), 11.0, Constants.COLOR_FIRE_GLOW)
	var flames: Array = [
		[Vector2(cx - 7, cy + 7), Vector2(cx - 1, cy - 10), Vector2(cx + 5, cy + 7)],
		[Vector2(cx - 4, cy + 7), Vector2(cx - 2, cy - 5), Vector2(cx + 2, cy + 7)],
		[Vector2(cx + 2, cy + 7), Vector2(cx + 5, cy - 8), Vector2(cx + 9, cy + 7)],
	]
	var fire_colors: Array = [
		Constants.COLOR_FIRE_MID,
		Constants.COLOR_FIRE_HOT,
		Constants.COLOR_FIRE_LOW,
	]
	for i: int in 3:
		draw_colored_polygon(PackedVector2Array(flames[i]), fire_colors[i])

func _draw_spike(cx: float, cy: float) -> void:
	draw_rect(Rect2(cx - 12, cy + 4, 24, 4), Constants.COLOR_STONE_DARK)
	var spike_color := Constants.COLOR_STONE
	for i: int in 4:
		var bx: float = cx - 9.0 + i * 6.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(bx - 3, cy + 8),
			Vector2(bx,     cy - 8),
			Vector2(bx + 3, cy + 8),
		]), spike_color)

func _draw_key(cx: float, cy: float) -> void:
	var gold := Constants.COLOR_GOLD
	var dark_gold := Constants.COLOR_GOLD_DARK
	draw_circle(Vector2(cx - 4, cy - 3), 6.5, gold)
	draw_circle(Vector2(cx - 4, cy - 3), 3.5, dark_gold)
	draw_rect(Rect2(cx - 4, cy - 4, 13, 3), gold)
	draw_rect(Rect2(cx + 4, cy - 1, 3, 3), gold)
	draw_rect(Rect2(cx + 8, cy - 1, 2, 2), gold)

func _draw_chest(cx: float, cy: float) -> void:
	var wood      := Constants.COLOR_WOOD
	var dark_wood := Constants.COLOR_WOOD_DARK
	var metal     := Constants.COLOR_METAL
	var penta     := Constants.COLOR_PENTAGRAM

	draw_rect(Rect2(cx - 13, cy - 1,  26, 12), dark_wood)
	draw_rect(Rect2(cx - 12, cy,       24, 10), wood)
	draw_rect(Rect2(cx - 13, cy - 11, 26,  10), dark_wood)
	draw_rect(Rect2(cx - 12, cy - 10, 24,  8), wood)
	draw_rect(Rect2(cx - 13, cy - 1,  26,  2), metal)
	draw_rect(Rect2(cx - 3,  cy - 4,   6,  4), metal)
	draw_circle(Vector2(cx, cy - 2), 2.0, dark_wood)

	_draw_inverted_pentagram(Vector2(cx, cy - 6), 4.5, penta)

func _draw_inverted_pentagram(center: Vector2, radius: float, color: Color) -> void:
	var inner_r: float = radius * 0.382
	var pts: PackedVector2Array = []
	for i: int in 10:
		var angle: float = PI / 2.0 + i * PI / 5.0
		var r: float = radius if i % 2 == 0 else inner_r
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(pts, color)

# ─── Decorações (ambientação folk-horror, não-bloqueantes) ──
func _draw_dead_tree(cx: float, cy: float) -> void:
	var bark      := Constants.COLOR_BARK
	var bark_dark := Constants.COLOR_BARK_DARK
	# tronco
	draw_rect(Rect2(cx - 2.5, cy - 4, 5, 16), bark_dark)
	draw_rect(Rect2(cx - 1.5, cy - 4, 3, 16), bark)
	# galhos secos retorcidos
	var branches: Array = [
		[Vector2(cx, cy - 2),  Vector2(cx - 9, cy - 9)],
		[Vector2(cx, cy - 4),  Vector2(cx + 8, cy - 11)],
		[Vector2(cx, cy - 1),  Vector2(cx + 6, cy - 3)],
		[Vector2(cx, cy - 6),  Vector2(cx - 5, cy - 13)],
	]
	for b: Array in branches:
		draw_line(b[0], b[1], bark, 2.0)

func _draw_bones(cx: float, cy: float) -> void:
	var bone := Constants.COLOR_BONE
	var hollow := Constants.COLOR_BONE_HOLLOW
	# crânio
	draw_circle(Vector2(cx - 3, cy - 1), 5.0, bone)
	draw_circle(Vector2(cx - 5, cy - 2), 1.3, hollow)
	draw_circle(Vector2(cx - 1, cy - 2), 1.3, hollow)
	draw_rect(Rect2(cx - 4, cy + 2, 3, 2), bone)
	# ossos cruzados
	draw_line(Vector2(cx + 1, cy + 5), Vector2(cx + 10, cy - 2), bone, 2.0)
	draw_line(Vector2(cx + 1, cy - 2), Vector2(cx + 10, cy + 5), bone, 2.0)

func _draw_moss(cx: float, cy: float) -> void:
	var moss      := Constants.COLOR_MOSS_DECO
	var moss_dark := Constants.COLOR_MOSS_DECO_DARK
	var blobs: Array = [
		[Vector2(cx - 6, cy + 4), 6.0], [Vector2(cx + 5, cy + 6), 5.0],
		[Vector2(cx + 7, cy - 4), 4.0], [Vector2(cx - 4, cy - 5), 4.5],
		[Vector2(cx + 1, cy + 1), 5.5],
	]
	for b: Array in blobs:
		draw_circle(b[0], b[1], moss)
	draw_circle(Vector2(cx - 5, cy + 5), 2.5, moss_dark)
	draw_circle(Vector2(cx + 6, cy - 3), 2.0, moss_dark)

func _draw_blood_pool(cx: float, cy: float) -> void:
	var blood      := Constants.COLOR_BLOOD_POOL
	var blood_dark := Constants.COLOR_BLOOD_POOL_DARK
	var pool: PackedVector2Array = [
		Vector2(cx - 9, cy + 1), Vector2(cx - 5, cy - 5), Vector2(cx + 2, cy - 6),
		Vector2(cx + 8, cy - 2), Vector2(cx + 9, cy + 4), Vector2(cx + 3, cy + 8),
		Vector2(cx - 4, cy + 7), Vector2(cx - 10, cy + 5),
	]
	draw_colored_polygon(pool, blood)
	draw_circle(Vector2(cx + 1, cy + 1), 3.5, blood_dark)
	# respingos
	draw_circle(Vector2(cx + 11, cy - 6), 1.5, blood)
	draw_circle(Vector2(cx - 12, cy - 3), 1.2, blood)

func _draw_rock(cx: float, cy: float) -> void:
	var stone      := Constants.COLOR_STONE
	var stone_dark := Constants.COLOR_STONE_DARK
	var rock: PackedVector2Array = [
		Vector2(cx - 8, cy + 6), Vector2(cx - 6, cy - 3), Vector2(cx, cy - 7),
		Vector2(cx + 7, cy - 2), Vector2(cx + 8, cy + 6),
	]
	draw_colored_polygon(rock, stone)
	var shade: PackedVector2Array = [
		Vector2(cx, cy - 7), Vector2(cx + 7, cy - 2), Vector2(cx + 8, cy + 6), Vector2(cx + 2, cy + 2),
	]
	draw_colored_polygon(shade, stone_dark)
