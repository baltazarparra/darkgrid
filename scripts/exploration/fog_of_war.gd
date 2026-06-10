class_name FogOfWar
extends CanvasLayer

# Cobre o mapa com escuridão e revela um raio circular ao redor da Caipora.
# Usar apenas na Fase 3. Puramente visual — não afeta lógica de turno.

@export var reveal_radius: float = 96.0

var _rect: ColorRect
var _shader_mat: ShaderMaterial
var _tracked_node: Node2D
var _last_uv: Vector2 = Vector2.INF
var _last_radius_uv: float = -1.0

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

func track(node: Node2D) -> void:
	_tracked_node = node

func _process(_delta: float) -> void:
	if _tracked_node == null:
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	update_position(_tracked_node.global_position, cam)

func update_position(world_pos: Vector2, cam: Camera2D) -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var vp_size := vp.get_visible_rect().size
	if vp_size == Vector2.ZERO:
		return
	var screen_pos := vp.get_canvas_transform() * world_pos
	var uv := screen_pos / vp_size
	var radius_uv := reveal_radius * cam.zoom.x / vp_size.y
	# Caipora parada (movimento em grid passa a maior parte do tempo parado):
	# uniforms não mudam — não reenviar params do shader todo frame.
	if uv.is_equal_approx(_last_uv) and is_equal_approx(radius_uv, _last_radius_uv):
		return
	_last_uv = uv
	_last_radius_uv = radius_uv
	_shader_mat.set_shader_parameter("player_screen_uv", uv)
	_shader_mat.set_shader_parameter("reveal_radius_uv", radius_uv)
