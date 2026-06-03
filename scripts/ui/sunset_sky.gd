class_name SunsetSky
extends Node2D

## Céu de por do sol para a cena final. Gradiente estático do topo (noite roxa)
## até o horizonte (dourado âmbar), com disco solar acima da treeline.

const BANDS: int = 60

# Paradas do gradiente: [t, Color]
const _STOPS: Array = [
	[0.00, Color(0.05, 0.02, 0.12)],
	[0.35, Color(0.25, 0.08, 0.15)],
	[0.60, Color(0.70, 0.20, 0.04)],
	[0.80, Color(0.92, 0.45, 0.05)],
	[1.00, Color(1.00, 0.78, 0.18)],
]

func _ready() -> void:
	z_index = -100
	queue_redraw()
	get_viewport().size_changed.connect(func() -> void:
		queue_redraw()
	)

func _draw() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var band_h: float = vp.y / float(BANDS) + 1.0
	for i: int in BANDS:
		var t: float = float(i) / float(BANDS - 1)
		draw_rect(Rect2(0.0, t * vp.y - band_h * 0.5, vp.x, band_h), _sky_color(t))
	# Halo solar (brilho difuso)
	var sx: float = vp.x * 0.62
	var sy: float = vp.y * 0.66
	draw_circle(Vector2(sx, sy), 70.0, Color(1.0, 0.55, 0.10, 0.18))
	draw_circle(Vector2(sx, sy), 52.0, Color(1.0, 0.62, 0.15, 0.30))
	# Disco solar
	draw_circle(Vector2(sx, sy), 44.0, Color(1.0, 0.62, 0.20))
	draw_circle(Vector2(sx, sy), 28.0, Color(1.0, 0.90, 0.55))

func _sky_color(t: float) -> Color:
	for i: int in range(_STOPS.size() - 1):
		var t0: float = _STOPS[i][0]
		var t1: float = _STOPS[i + 1][0]
		if t <= t1:
			var f: float = (t - t0) / (t1 - t0)
			return (_STOPS[i][1] as Color).lerp(_STOPS[i + 1][1], f)
	return _STOPS[-1][1]
