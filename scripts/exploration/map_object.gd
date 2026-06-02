class_name MapObject
extends Node2D

enum Type { CHEST, KEY, FIRE, SPIKE }

const T: int = Constants.TILE_SIZE  # 32

var _type: Type

# ─── Public API ────────────────────────────────────
func setup(type: Type, grid_pos: Vector2i) -> void:
	_type = type
	position = Vector2(grid_pos) * T
	queue_redraw()

# ─── Drawing ───────────────────────────────────────
func _draw() -> void:
	var cx: float = T / 2.0
	var cy: float = T / 2.0
	match _type:
		Type.CHEST:  _draw_chest(cx, cy)
		Type.KEY:    _draw_key(cx, cy)
		Type.FIRE:   _draw_fire(cx, cy)
		Type.SPIKE:  _draw_spike(cx, cy)

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
