class_name FogOfWar
extends CanvasLayer

# Cobre o mapa com escuridão e revela um raio circular ao redor da Caipora.
# Usar apenas na Fase 3. Puramente visual — não afeta lógica de turno.

@export var reveal_radius: float = 96.0

var _rect: ColorRect
var _shader_mat: ShaderMaterial

func _ready() -> void:
	layer = 10
	_rect = ColorRect.new()
	_rect.anchor_right = 1.0
	_rect.anchor_bottom = 1.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = load("res://shaders/fog_reveal.gdshader")
	_rect.material = _shader_mat
	add_child(_rect)

func update_position(world_pos: Vector2, cam: Camera2D) -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var vp_size := vp.get_visible_rect().size
	if vp_size == Vector2.ZERO:
		return
	var screen_pos := vp.get_canvas_transform() * world_pos
	var uv := screen_pos / vp_size
	_shader_mat.set_shader_parameter("player_screen_uv", uv)
	var radius_world := reveal_radius * cam.zoom.x
	_shader_mat.set_shader_parameter("reveal_radius_uv", radius_world / vp_size.y)
