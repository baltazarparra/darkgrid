class_name HealthIcons
extends Control

enum Shape { PENTAGRAM, STAR_OF_DAVID }

# ─── Constants ─────────────────────────────────────
const ICON_RADIUS: float = 12.0
const ICON_SPACING: float = 30.0

# ─── State ─────────────────────────────────────────
var _shape: Shape = Shape.PENTAGRAM
var _total: int = 5
var _current: int = 5
var _active_color: Color = Constants.COLOR_BLOOD
var _empty_color: Color = Constants.COLOR_BLOOD_EMPTY
var _radius: float = ICON_RADIUS
var _spacing: float = ICON_SPACING

# ─── Public API ────────────────────────────────────
func setup(total: int, shape: Shape, active: Color, empty: Color, radius: float = ICON_RADIUS, spacing: float = ICON_SPACING) -> void:
	_total = total
	_current = total
	_shape = shape
	_active_color = active
	_empty_color = empty
	_radius = radius
	_spacing = spacing
	custom_minimum_size = Vector2(_total * _spacing + _radius, _radius * 2.8)
	queue_redraw()

func set_current(n: float) -> void:
	_current = clampi(ceili(n), 0, _total)
	queue_redraw()

## Atualiza só o tamanho dos ícones (sem mexer em total/atual). Usado no resize.
func set_metrics(radius: float, spacing: float) -> void:
	_radius = radius
	_spacing = spacing
	custom_minimum_size = Vector2(_total * _spacing + _radius, _radius * 2.8)
	queue_redraw()

# ─── Drawing ───────────────────────────────────────
func _draw() -> void:
	var cy: float = custom_minimum_size.y * 0.5
	for i: int in _total:
		var center := Vector2(_radius + i * _spacing, cy)
		var color: Color = _active_color if i < _current else _empty_color
		if _shape == Shape.PENTAGRAM:
			_draw_pentagram(center, _radius, color)
		else:
			_draw_star_of_david(center, _radius, color)

func _draw_pentagram(center: Vector2, radius: float, color: Color) -> void:
	var inner_r: float = radius * 0.382
	var pts: PackedVector2Array = []
	for i: int in 10:
		var angle: float = PI / 2.0 + i * PI / 5.0
		var r: float = radius if i % 2 == 0 else inner_r
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(pts, color)

func _draw_star_of_david(center: Vector2, radius: float, color: Color) -> void:
	var inner_r: float = radius * 0.577
	var pts: PackedVector2Array = []
	for i: int in 6:
		var a_out: float = -PI / 2.0 + i * TAU / 6.0
		var a_in: float = a_out + TAU / 12.0
		pts.append(center + Vector2(cos(a_out), sin(a_out)) * radius)
		pts.append(center + Vector2(cos(a_in), sin(a_in)) * inner_r)
	draw_colored_polygon(pts, color)
