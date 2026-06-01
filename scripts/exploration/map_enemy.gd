class_name MapEnemy
extends Node2D

# ─── Constants ─────────────────────────────────────
const ENEMY_TEXTURE = preload("res://assets/sprites/enemy_idle.png")
const CHASE_RANGE := 5

# ─── State ─────────────────────────────────────────
var enemy_id: String = ""
var grid_pos: Vector2i = Vector2i.ZERO
var is_boss: bool = false

# ─── Public API ────────────────────────────────────
func setup(id: String, pos: Vector2i, boss: bool = false) -> void:
	enemy_id = id
	grid_pos = pos
	is_boss = boss
	_update_visual_position()

	var sprite := Sprite2D.new()
	sprite.texture = ENEMY_TEXTURE
	sprite.modulate = Color(1.0, 0.2, 0.2, 1.0) if boss else Color(0.7, 0.5, 0.9, 1.0)
	add_child(sprite)

## Returns true if this enemy reaches the player and should trigger combat.
func take_turn(player_pos: Vector2i, walkable_fn: Callable, occupied_fn: Callable) -> bool:
	var dist := _manhattan(grid_pos, player_pos)
	if dist <= 1:
		return true

	var new_pos: Vector2i
	if dist <= CHASE_RANGE:
		new_pos = _chase(player_pos, walkable_fn, occupied_fn)
	else:
		new_pos = _wander(walkable_fn, occupied_fn)

	if new_pos != grid_pos:
		grid_pos = new_pos
		_update_visual_position()
		if grid_pos == player_pos:
			return true

	return false

# ─── Private ───────────────────────────────────────
func _update_visual_position() -> void:
	position = Vector2(grid_pos) * Constants.TILE_SIZE

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _chase(target: Vector2i, walkable_fn: Callable, occupied_fn: Callable) -> Vector2i:
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	dirs.shuffle()
	var best := grid_pos
	var best_dist := _manhattan(grid_pos, target)
	for d: Vector2i in dirs:
		var np: Vector2i = grid_pos + d
		if walkable_fn.call(np) and not occupied_fn.call(np):
			var dist := _manhattan(np, target)
			if dist < best_dist:
				best_dist = dist
				best = np
	return best

func _wander(walkable_fn: Callable, occupied_fn: Callable) -> Vector2i:
	if randf() > 0.4:
		return grid_pos
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	dirs.shuffle()
	for d: Vector2i in dirs:
		var np: Vector2i = grid_pos + d
		if walkable_fn.call(np) and not occupied_fn.call(np):
			return np
	return grid_pos
