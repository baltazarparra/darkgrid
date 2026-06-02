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
	draw_circle(Vector2(cx, cy), 11.0, Color(0.55, 0.08, 0.0, 0.35))
	var flames: Array = [
		[Vector2(cx - 7, cy + 7), Vector2(cx - 1, cy - 10), Vector2(cx + 5, cy + 7)],
		[Vector2(cx - 4, cy + 7), Vector2(cx - 2, cy - 5), Vector2(cx + 2, cy + 7)],
		[Vector2(cx + 2, cy + 7), Vector2(cx + 5, cy - 8), Vector2(cx + 9, cy + 7)],
	]
	var fire_colors: Array = [
		Color(0.85, 0.30, 0.0),
		Color(1.00, 0.55, 0.05),
		Color(0.75, 0.20, 0.0),
	]
	for i: int in 3:
		draw_colored_polygon(PackedVector2Array(flames[i]), fire_colors[i])

func _draw_spike(cx: float, cy: float) -> void:
	draw_rect(Rect2(cx - 12, cy + 4, 24, 4), Color(0.22, 0.22, 0.25))
	var spike_color := Color(0.42, 0.42, 0.47)
	for i: int in 4:
		var bx: float = cx - 9.0 + i * 6.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(bx - 3, cy + 8),
			Vector2(bx,     cy - 8),
			Vector2(bx + 3, cy + 8),
		]), spike_color)

func _draw_key(cx: float, cy: float) -> void:
	var gold := Color(0.92, 0.78, 0.12)
	var dark_gold := Color(0.55, 0.42, 0.04)
	draw_circle(Vector2(cx - 4, cy - 3), 6.5, gold)
	draw_circle(Vector2(cx - 4, cy - 3), 3.5, dark_gold)
	draw_rect(Rect2(cx - 4, cy - 4, 13, 3), gold)
	draw_rect(Rect2(cx + 4, cy - 1, 3, 3), gold)
	draw_rect(Rect2(cx + 8, cy - 1, 2, 2), gold)

func _draw_chest(cx: float, cy: float) -> void:
	var wood      := Color(0.32, 0.17, 0.04)
	var dark_wood := Color(0.16, 0.07, 0.01)
	var metal     := Color(0.48, 0.38, 0.10)
	var penta     := Color(0.50, 0.0,  0.0)

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
	var bark      := Color(0.18, 0.11, 0.05)
	var bark_dark := Color(0.10, 0.06, 0.02)
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
	var bone := Color(0.78, 0.74, 0.62)
	var hollow := Color(0.12, 0.10, 0.08)
	# crânio
	draw_circle(Vector2(cx - 3, cy - 1), 5.0, bone)
	draw_circle(Vector2(cx - 5, cy - 2), 1.3, hollow)
	draw_circle(Vector2(cx - 1, cy - 2), 1.3, hollow)
	draw_rect(Rect2(cx - 4, cy + 2, 3, 2), bone)
	# ossos cruzados
	draw_line(Vector2(cx + 1, cy + 5), Vector2(cx + 10, cy - 2), bone, 2.0)
	draw_line(Vector2(cx + 1, cy - 2), Vector2(cx + 10, cy + 5), bone, 2.0)

func _draw_moss(cx: float, cy: float) -> void:
	var moss      := Color(0.13, 0.24, 0.10, 0.7)
	var moss_dark := Color(0.08, 0.16, 0.06, 0.7)
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
	var blood      := Color(0.42, 0.02, 0.02, 0.75)
	var blood_dark := Color(0.24, 0.0, 0.0, 0.8)
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
	var stone      := Color(0.34, 0.34, 0.38)
	var stone_dark := Color(0.20, 0.20, 0.24)
	var rock: PackedVector2Array = [
		Vector2(cx - 8, cy + 6), Vector2(cx - 6, cy - 3), Vector2(cx, cy - 7),
		Vector2(cx + 7, cy - 2), Vector2(cx + 8, cy + 6),
	]
	draw_colored_polygon(rock, stone)
	var shade: PackedVector2Array = [
		Vector2(cx, cy - 7), Vector2(cx + 7, cy - 2), Vector2(cx + 8, cy + 6), Vector2(cx + 2, cy + 2),
	]
	draw_colored_polygon(shade, stone_dark)
