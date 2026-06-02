class_name MapEnemy
extends Node2D

# ─── Constants ─────────────────────────────────────
const ENEMY_TEXTURE = preload("res://assets/sprites/enemy_idle.png")
const CHASE_RANGE := 5          # comuns: alcance de aggro
const BOSS_CHASE_RANGE := 7     # boss: defende a porta com alcance maior
const DRIFT_IDLE_CHANCE := 0.4  # chance de ficar parado ao voltar pra origem

# ─── State ─────────────────────────────────────────
var enemy_id: String = ""
var grid_pos: Vector2i = Vector2i.ZERO
var is_boss: bool = false
var home_pos: Vector2i = Vector2i.ZERO  # origem; alvo do leash quando o jogador foge

# ─── Public API ────────────────────────────────────
func setup(id: String, pos: Vector2i, boss: bool = false) -> void:
	enemy_id = id
	grid_pos = pos
	home_pos = pos
	is_boss = boss
	_update_visual_position()

	var sprite := Sprite2D.new()
	sprite.texture = ENEMY_TEXTURE
	sprite.modulate = Color(0.08, 0.0, 0.14, 1.0) if boss else Color(0.7, 0.5, 0.9, 1.0)
	add_child(sprite)

	if boss:
		_spawn_boss_aura()

## Returns true if this enemy reaches the player and should trigger combat.
func take_turn(player_pos: Vector2i, walkable_fn: Callable, occupied_fn: Callable) -> bool:
	var dist := _manhattan(grid_pos, player_pos)
	if dist <= 1:
		return true

	var aggro_range := BOSS_CHASE_RANGE if is_boss else CHASE_RANGE
	var new_pos: Vector2i
	if dist <= aggro_range:
		# Dentro do alcance: persegue o jogador.
		new_pos = _chase(player_pos, walkable_fn, occupied_fn)
	elif grid_pos != home_pos:
		# Fora do alcance (jogador fugiu): faz leash de volta pra origem.
		new_pos = _drift_home(walkable_fn, occupied_fn)
	else:
		# Já em casa e jogador longe: fica de guarda.
		new_pos = grid_pos

	if new_pos != grid_pos:
		grid_pos = new_pos
		_update_visual_position()
		if grid_pos == player_pos:
			return true

	return false

# ─── Private ───────────────────────────────────────
func _spawn_boss_aura() -> void:
	var aura := CPUParticles2D.new()
	aura.z_index = -1
	aura.amount = 16
	aura.lifetime = 1.4
	aura.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	aura.emission_sphere_radius = 14.0
	aura.gravity = Vector2(0, -10)
	aura.initial_velocity_min = 2.0
	aura.initial_velocity_max = 8.0
	aura.scale_amount_min = 1.5
	aura.scale_amount_max = 3.5
	aura.color = Color(0.18, 0.0, 0.28, 0.75)
	add_child(aura)

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

func _drift_home(walkable_fn: Callable, occupied_fn: Callable) -> Vector2i:
	if randf() < DRIFT_IDLE_CHANCE:
		return grid_pos
	return _chase(home_pos, walkable_fn, occupied_fn)
