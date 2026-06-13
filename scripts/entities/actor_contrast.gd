class_name ActorContrast
extends RefCounted

const ForestLight := preload("res://scripts/exploration/forest_light.gd")
const OUTLINE_SHADER := preload("res://shaders/enemy_outline.gdshader")

const SHADOW_NAME := "GroundShadow"
const FRONT_LIGHT_NAME := "FrontContrastLight"

static func add_ground_shadow(parent: Node2D, scale: Vector2,
		position: Vector2 = Vector2(0.0, 2.0),
		color: Color = Constants.COLOR_ACTOR_SHADOW) -> Sprite2D:
	if parent == null:
		return null
	var existing := parent.get_node_or_null(SHADOW_NAME) as Sprite2D
	if existing != null:
		existing.scale = scale
		existing.position = position
		existing.modulate = color
		return existing
	var shadow := Sprite2D.new()
	shadow.name = SHADOW_NAME
	shadow.texture = load(Constants.SHADOW_OVAL_PATH)
	shadow.z_index = -1
	shadow.modulate = color
	shadow.position = position
	shadow.scale = scale
	parent.add_child(shadow)
	return shadow

static func add_front_light(parent: Node2D, position: Vector2,
		energy: float = Constants.ACTOR_FRONT_LIGHT_ENERGY,
		texture_scale: float = Constants.ACTOR_FRONT_LIGHT_SCALE) -> PointLight2D:
	if parent == null:
		return null
	# Em dispositivos budget (Safari iOS antigo etc.) a PointLight2D per-ator é
	# polish dispensável — libera a pipeline de lighting para o timing crítico.
	var vp := parent.get_viewport()
	if vp != null and Constants.particle_amount_scale(vp.get_visible_rect().size) < 1.0:
		return null
	var existing := parent.get_node_or_null(FRONT_LIGHT_NAME) as PointLight2D
	if existing != null:
		existing.position = position
		existing.energy = energy
		existing.texture_scale = texture_scale
		return existing
	var light := ForestLight.make(Constants.COLOR_ACTOR_FRONT_LIGHT, energy, texture_scale)
	light.name = FRONT_LIGHT_NAME
	light.position = position
	parent.add_child(light)
	return light

static func apply_outline(sprite: CanvasItem,
		color: Color = Constants.COLOR_ACTOR_OUTLINE,
		thickness_px: float = Constants.ACTOR_OUTLINE_THICKNESS) -> void:
	if sprite == null:
		return
	var mat := sprite.material as ShaderMaterial
	if mat == null or mat.shader != OUTLINE_SHADER:
		mat = ShaderMaterial.new()
		mat.shader = OUTLINE_SHADER
		sprite.material = mat
	mat.set_shader_parameter("glow_color", color)
	mat.set_shader_parameter("glow_thickness_px", thickness_px)
