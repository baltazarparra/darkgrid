class_name ForestAmbience
extends Node2D

## Camadas atmosféricas da floresta da Fase 1 (profundidade premium): neblina rasteira,
## esporos/folhas à deriva e feixes de luz (god rays). PURAMENTE DECORATIVO. Segue o
## padrão de ambient_life.gd: CPUParticles2D (NUNCA GPUParticles2D — export web é
## gl_compatibility) + desenho procedural. Mantido separado de AmbientLife para não
## inchar aquele arquivo (uma responsabilidade por classe).

const SOFT_TEXTURE := preload("res://assets/sprites/light_radial.png")

const MIST_COUNT: int = 12
const SPORE_COUNT: int = 26
const RAY_COUNT: int = 3

# ─── State ─────────────────────────────────────────
var _bounds: Rect2 = Rect2(0, 0, 0, 0)
var _rays: Array[Dictionary] = []
var _t: float = 0.0

# ─── Public API ────────────────────────────────────
func setup(bounds: Rect2) -> void:
	_bounds = bounds
	# God rays atrás das entidades, somando luz sobre a noite (blend aditivo no _draw).
	z_index = -1
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	_spawn_mist()
	_spawn_spores()
	_setup_rays()
	set_process(true)

# ─── Lifecycle ─────────────────────────────────────
func _process(delta: float) -> void:
	_t += delta
	queue_redraw()  # god rays pulsam de leve

# ─── God rays (feixes de luz na copa) ──────────────
func _setup_rays() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210
	for i in RAY_COUNT:
		_rays.append({
			"x": _bounds.position.x + _bounds.size.x * rng.randf_range(0.2, 0.8),
			"w": rng.randf_range(34.0, 60.0),
			"phase": rng.randf() * TAU,
			"speed": rng.randf_range(0.25, 0.5),
		})

func _draw() -> void:
	var top := _bounds.position.y
	var bottom := _bounds.end.y
	var slant := 90.0  # deslocamento horizontal do topo à base (diagonal de copa)
	for r in _rays:
		var x: float = r["x"]
		var w: float = r["w"]
		var a: float = 0.05 + 0.035 * sin(_t * r["speed"] + r["phase"])
		var col := Color(1.0, 0.85, 0.55, maxf(a, 0.0))
		var poly := PackedVector2Array([
			Vector2(x, top),
			Vector2(x + w, top),
			Vector2(x + w + slant, bottom),
			Vector2(x + slant, bottom),
		])
		draw_colored_polygon(poly, col)

# ─── Neblina rasteira ──────────────────────────────
func _spawn_mist() -> void:
	var mist := CPUParticles2D.new()
	mist.texture = SOFT_TEXTURE
	mist.z_index = -1
	mist.position = _bounds.position + _bounds.size * 0.5
	mist.amount = MIST_COUNT
	mist.lifetime = 9.0
	mist.preprocess = 9.0
	mist.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	mist.emission_rect_extents = Vector2(_bounds.size.x * 0.5, _bounds.size.y * 0.45)
	mist.direction = Vector2(1, 0)
	mist.spread = 25.0
	mist.gravity = Vector2.ZERO
	mist.initial_velocity_min = 3.0
	mist.initial_velocity_max = 9.0
	mist.scale_amount_min = 0.5
	mist.scale_amount_max = 1.1
	mist.color_ramp = _mist_ramp()
	add_child(mist)

func _mist_ramp() -> Gradient:
	# Cinza-azulado translúcido que acende e some (deriva fantasmagórica).
	var c := Color(0.30, 0.36, 0.44)
	var grad := Gradient.new()
	grad.set_offset(0, 0.0); grad.set_color(0, Color(c.r, c.g, c.b, 0.0))
	grad.set_offset(1, 1.0); grad.set_color(1, Color(c.r, c.g, c.b, 0.0))
	grad.add_point(0.5, Color(c.r, c.g, c.b, 0.16))
	return grad

# ─── Esporos / folhas à deriva ─────────────────────
func _spawn_spores() -> void:
	var spores := CPUParticles2D.new()
	spores.z_index = 1
	spores.position = _bounds.position + _bounds.size * 0.5
	spores.amount = SPORE_COUNT
	spores.lifetime = 7.0
	spores.preprocess = 7.0
	spores.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	spores.emission_rect_extents = Vector2(_bounds.size.x * 0.5, _bounds.size.y * 0.5)
	spores.direction = Vector2(0.3, 1)  # caem com leve deriva lateral
	spores.spread = 35.0
	spores.gravity = Vector2(2.0, 6.0)  # queda muito lenta
	spores.initial_velocity_min = 2.0
	spores.initial_velocity_max = 6.0
	spores.scale_amount_min = 1.0
	spores.scale_amount_max = 2.2
	spores.color_ramp = _spore_ramp()
	# Blend aditivo: brilham fraco sobre a escuridão (poeira encantada).
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	spores.material = glow
	add_child(spores)

func _spore_ramp() -> Gradient:
	var amber := Constants.COLOR_AMBER
	var grad := Gradient.new()
	grad.set_offset(0, 0.0); grad.set_color(0, Color(0.5, 0.7, 0.4, 0.0))
	grad.set_offset(1, 1.0); grad.set_color(1, Color(amber.r, amber.g, amber.b, 0.0))
	grad.add_point(0.4, Color(0.6, 0.75, 0.45, 0.5))
	grad.add_point(0.7, Color(0.9, 0.7, 0.35, 0.4))
	return grad
