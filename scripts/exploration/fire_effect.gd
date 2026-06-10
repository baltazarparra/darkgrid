class_name FireEffect
extends RefCounted

## Fábrica do efeito de fogueira viva: luz quente (PointLight2D com flicker) + três
## camadas de partículas (fumaça/chama/brasas). Centraliza o que antes vivia preso em
## `MapObject` para reuso pela Caipora flamejante na Fase 3 e pelas fogueiras das
## Fases 1 e 2. Tudo CPUParticles2D (web-safe / gl_compatibility).
##
## `attach()` deve ser chamado com `target` já na SceneTree — o flicker usa
## `target.create_tween()`, que se vincula ao nó.

const ForestLight := preload("res://scripts/exploration/forest_light.gd")

# Anexa luz + partículas de fogo a `target`, centradas em `center` (coords locais).
# `light_scale`: escala da textura radial (0.8 ≈ 3 tiles, 1.5 ≈ 6 tiles).
static func attach(target: Node2D, center: Vector2, light_scale: float) -> void:
	_attach_fire_light(target, center, light_scale)
	_attach_fire_particles(target, center)

# Poça de luz quente da fogueira, com flicker irregular (chama viva).
static func _attach_fire_light(target: Node2D, center: Vector2, light_scale: float) -> void:
	var light := ForestLight.make(Constants.COLOR_FIRE_HOT, 1.0, light_scale)
	light.position = center
	target.add_child(light)
	var tween := target.create_tween().set_loops()
	tween.tween_property(light, "energy", 1.15, 0.18).set_trans(Tween.TRANS_SINE)
	tween.tween_property(light, "energy", 0.82, 0.13).set_trans(Tween.TRANS_SINE)
	tween.tween_property(light, "energy", 1.05, 0.21).set_trans(Tween.TRANS_SINE)
	tween.tween_property(light, "energy", 0.9, 0.16).set_trans(Tween.TRANS_SINE)

# Chama viva + brasas (aditivo) + fumaça (mix). Tudo CPUParticles2D (web-safe).
static func _attach_fire_particles(target: Node2D, center: Vector2) -> void:
	var base := center + Vector2(0, 4.0)

	# Fumaça: cinza translúcido, lenta, sobe e dissipa (atrás da chama).
	var smoke := _make_particles(10, 1.8, base, Vector2(0, -18), 8.0, 20.0, 0.12, 0.25,
		_smoke_ramp(), false)
	smoke.texture = ForestLight.LIGHT_TEXTURE  # puff redondo e suave (não quadrado)
	smoke.spread = 22.0
	smoke.z_index = -1
	target.add_child(smoke)

	# Chama: gradiente quente, sobe rápido, blend aditivo.
	var flame := _make_particles(18, 0.6, base, Vector2(0, -45), 14.0, 34.0, 2.0, 4.0,
		_flame_ramp(), true)
	flame.spread = 16.0
	target.add_child(flame)

	# Brasas: poucas, rápidas, sobem alto (faísca da fogueira).
	var embers := _make_particles(8, 1.1, base, Vector2(0, -60), 20.0, 50.0, 1.0, 2.2,
		_ember_ramp(), true)
	embers.spread = 30.0
	embers.z_index = 1
	target.add_child(embers)

static func _make_particles(amount: int, lifetime: float, pos: Vector2, gravity: Vector2,
		vmin: float, vmax: float, smin: float, smax: float, ramp: Gradient,
		additive: bool) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.preprocess = lifetime
	p.position = pos
	p.direction = Vector2(0, -1)
	p.gravity = gravity
	p.initial_velocity_min = vmin
	p.initial_velocity_max = vmax
	p.scale_amount_min = smin
	p.scale_amount_max = smax
	p.color_ramp = ramp
	if additive:
		p.material = Constants.ADDITIVE_MATERIAL
	return p

static func _flame_ramp() -> Gradient:
	var grad := Gradient.new()
	grad.set_offset(0, 0.0); grad.set_color(0, Constants.COLOR_FIRE_HOT)
	grad.set_offset(1, 1.0); grad.set_color(1, Color(Constants.COLOR_FIRE_LOW.r, Constants.COLOR_FIRE_LOW.g, Constants.COLOR_FIRE_LOW.b, 0.0))
	grad.add_point(0.5, Constants.COLOR_FIRE_MID)
	return grad

static func _ember_ramp() -> Gradient:
	var amber := Constants.COLOR_AMBER
	var grad := Gradient.new()
	grad.set_offset(0, 0.0); grad.set_color(0, Color(1.0, 0.6, 0.2, 0.9))
	grad.set_offset(1, 1.0); grad.set_color(1, Color(amber.r, amber.g, amber.b, 0.0))
	return grad

static func _smoke_ramp() -> Gradient:
	var grad := Gradient.new()
	grad.set_offset(0, 0.0); grad.set_color(0, Color(0.15, 0.13, 0.14, 0.0))
	grad.set_offset(1, 1.0); grad.set_color(1, Color(0.10, 0.09, 0.10, 0.0))
	grad.add_point(0.35, Color(0.18, 0.16, 0.17, 0.35))
	return grad
