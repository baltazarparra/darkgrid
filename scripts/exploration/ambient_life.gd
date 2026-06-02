class_name AmbientLife
extends Node2D

## Vida ambiente da floresta amazônica: vaga-lumes flutuando (âmbar, pulsando) e
## insetos rastejando pelo chão. PURAMENTE DECORATIVO — não bloqueia nem interage
## com o jogador. Segue o padrão procedural de map_object.gd (zero assets).
##
## Vaga-lumes usam CPUParticles2D (NUNCA GPUParticles2D: export web é gl_compatibility
## com thread_support=false). Insetos são desenhados via _draw + _process.

# ─── Constants ─────────────────────────────────────
const FIREFLY_COUNT: int = 44
const INSECT_COUNT: int = 16
const INSECT_SPEED: float = 7.0
const INSECT_REPATH_MIN: float = 0.7
const INSECT_REPATH_MAX: float = 2.2
const INSECT_BODY := Color(0.14, 0.11, 0.08, 0.95)
const INSECT_LEG := Color(0.20, 0.15, 0.11, 0.8)

# ─── State ─────────────────────────────────────────
var _bounds: Rect2 = Rect2(0, 0, 0, 0)
var _insects: Array[Dictionary] = []

# ─── Public API ────────────────────────────────────
## `bounds` é a área (em pixels) onde a vida ambiente pode aparecer.
func setup(bounds: Rect2) -> void:
	_bounds = bounds
	z_index = -1  # insetos no chão, atrás de jogador/inimigos
	_spawn_fireflies()
	_spawn_insects()
	set_process(true)

# ─── Lifecycle ─────────────────────────────────────
func _process(delta: float) -> void:
	for ins in _insects:
		ins.timer -= delta
		if ins.timer <= 0.0:
			var ang: float = randf() * TAU
			ins.vel = Vector2(cos(ang), sin(ang)) * INSECT_SPEED
			ins.timer = randf_range(INSECT_REPATH_MIN, INSECT_REPATH_MAX)
		ins.pos += ins.vel * delta
		# rebatе nas bordas (mantém dentro da área)
		if ins.pos.x < _bounds.position.x or ins.pos.x > _bounds.end.x:
			ins.vel.x = -ins.vel.x
		if ins.pos.y < _bounds.position.y or ins.pos.y > _bounds.end.y:
			ins.vel.y = -ins.vel.y
		ins.pos.x = clampf(ins.pos.x, _bounds.position.x, _bounds.end.x)
		ins.pos.y = clampf(ins.pos.y, _bounds.position.y, _bounds.end.y)
	queue_redraw()

# ─── Drawing (insetos) ─────────────────────────────
func _draw() -> void:
	for ins in _insects:
		var p: Vector2 = ins.pos
		var heading: Vector2 = ins.vel.normalized() if ins.vel.length() > 0.01 else Vector2.RIGHT
		var perp := Vector2(-heading.y, heading.x)
		# 3 pares de perninhas
		for k in range(-1, 2):
			var seg: Vector2 = p + heading * (k * 1.6)
			draw_line(seg, seg + perp * 2.2, INSECT_LEG, 1.0)
			draw_line(seg, seg - perp * 2.2, INSECT_LEG, 1.0)
		# corpo (duas elipses pequenas)
		draw_circle(p + heading * 1.4, 1.3, INSECT_BODY)
		draw_circle(p - heading * 1.0, 1.7, INSECT_BODY)

# ─── Private helpers ───────────────────────────────
func _spawn_fireflies() -> void:
	var fireflies := CPUParticles2D.new()
	fireflies.z_index = 1  # flutuam acima do chão
	fireflies.position = _bounds.position + _bounds.size * 0.5
	fireflies.amount = FIREFLY_COUNT
	fireflies.lifetime = 4.5
	fireflies.preprocess = 4.5  # já espalhados ao iniciar
	fireflies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fireflies.emission_rect_extents = Vector2(_bounds.size.x * 0.5, _bounds.size.y * 0.5)
	fireflies.direction = Vector2(0, -1)
	fireflies.spread = 180.0
	fireflies.gravity = Vector2.ZERO
	fireflies.initial_velocity_min = 3.0
	fireflies.initial_velocity_max = 9.0
	fireflies.scale_amount_min = 1.5
	fireflies.scale_amount_max = 3.2
	fireflies.color_ramp = _firefly_glow_ramp()
	# Blend aditivo: o brilho fura o CanvasModulate da noite (vaga-lume realmente acende).
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fireflies.material = glow
	add_child(fireflies)

## Gradiente de alpha ao longo da vida: acende e apaga (pulso de vaga-lume).
func _firefly_glow_ramp() -> Gradient:
	var amber := Constants.COLOR_AMBER
	var grad := Gradient.new()
	grad.set_offset(0, 0.0)
	grad.set_color(0, Color(amber.r, amber.g, amber.b, 0.0))
	grad.set_offset(1, 1.0)
	grad.set_color(1, Color(amber.r, amber.g, amber.b, 0.0))
	grad.add_point(0.3, Color(amber.r, amber.g, amber.b, 1.0))
	grad.add_point(0.65, Color(1.0, 0.85, 0.4, 0.9))
	return grad

func _spawn_insects() -> void:
	for i in INSECT_COUNT:
		_insects.append({
			"pos": Vector2(
				randf_range(_bounds.position.x, _bounds.end.x),
				randf_range(_bounds.position.y, _bounds.end.y)
			),
			"vel": Vector2.ZERO,
			"timer": randf_range(0.0, INSECT_REPATH_MAX),
		})
