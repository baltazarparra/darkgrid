class_name Caipora
extends CharacterBody2D

# ─── Exports ───────────────────────────────────────
@export var tilemap: TileMap
@export var move_duration: float = 0.15

# ─── Signals ───────────────────────────────────────
signal move_finished(new_grid_pos: Vector2i)

# ─── State ─────────────────────────────────────────
var _is_moving: bool = false

# ─── Onready ───────────────────────────────────────
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _camera: Camera2D = $Camera2D
@onready var _light: PointLight2D = $PointLight2D

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	collision_layer = 1 << (Constants.LAYER_PLAYER - 1)
	collision_mask = 1 << (Constants.LAYER_WALL - 1)

	# Camera limits
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = Constants.GRID_WIDTH * Constants.TILE_SIZE
	_camera.limit_bottom = Constants.GRID_HEIGHT * Constants.TILE_SIZE
	_camera.limit_smoothed = true
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 10.0

	# Light
	_light.energy = 1.5
	_light.blend_mode = PointLight2D.BLEND_MODE_MIX
	_light.texture_scale = 3.0

func _process(_delta: float) -> void:
	if _is_moving:
		return
	var input_dir := _get_cardinal_input()
	if input_dir != Vector2.ZERO:
		_try_move(input_dir)

# ─── Public API ────────────────────────────────────
func try_move(direction: Vector2) -> void:
	_try_move(direction)

# ─── Private helpers ───────────────────────────────
func _get_cardinal_input() -> Vector2:
	var x := int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	var y := int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	return Vector2(x, y)

func _try_move(dir: Vector2) -> void:
	var target := position + dir * Constants.TILE_SIZE

	if _would_collide(target):
		return

	_is_moving = true
	_animated_sprite.flip_h = dir.x < 0
	_animated_sprite.play("walk")

	var tween := create_tween()
	tween.tween_property(self, "position", target, move_duration)
	tween.tween_callback(_on_move_finished)

func _would_collide(target: Vector2) -> bool:
	if tilemap == null:
		return true
	var grid_pos := tilemap.local_to_map(target)
	var tile_data := tilemap.get_cell_tile_data(0, grid_pos)
	if tile_data == null:
		return true
	return tilemap.get_cell_source_id(0, grid_pos) == 1

func _on_move_finished() -> void:
	_is_moving = false
	_animated_sprite.play("idle")
	if tilemap != null:
		move_finished.emit(tilemap.local_to_map(position))
