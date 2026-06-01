class_name FeedbackSystem
extends Node

const BLOOD_PARTICLES := preload("res://scenes/shared/blood_particles.tscn")
const CRITICAL_PARTICLES := preload("res://scenes/shared/critical_particles.tscn")
const DEATH_PARTICLES := preload("res://scenes/shared/death_particles.tscn")

@export var shake_intensity: float = 8.0
@export var shake_duration: float = 0.3

var _hit_stop_active: bool = false

# ─── Screenshake ───────────────────────────────────
func trigger_screenshake(intensity: float = shake_intensity, duration: float = shake_duration) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var original_offset := camera.offset
	var tween := create_tween()
	tween.tween_method(_shake_camera.bind(camera), intensity, 0.0, duration)
	tween.tween_callback(func(): camera.offset = original_offset)

func _shake_camera(amount: float, camera: Camera2D) -> void:
	camera.offset = Vector2(
		randf_range(-amount, amount),
		randf_range(-amount, amount)
	)

# ─── Hit-stop ──────────────────────────────────────
## Congela o jogo por N frames (60fps de referência) via Engine.time_scale.
## O timer usa ignore_time_scale=true para não congelar a si mesmo.
## Anti-acúmulo: hit-stops simultâneos são ignorados se já houver um ativo.
func trigger_hit_stop(frames: int = 3) -> void:
	if _hit_stop_active:
		return
	_hit_stop_active = true
	Engine.time_scale = 0.0
	await get_tree().create_timer(frames / 60.0, true, false, true).timeout
	Engine.time_scale = 1.0
	_hit_stop_active = false

# ─── Partículas ────────────────────────────────────
func spawn_blood_particles(at_position: Vector2) -> void:
	_spawn_particles(BLOOD_PARTICLES, at_position)

func spawn_critical_particles(at_position: Vector2) -> void:
	_spawn_particles(CRITICAL_PARTICLES, at_position)

func spawn_death_particles(at_position: Vector2) -> void:
	_spawn_particles(DEATH_PARTICLES, at_position)

func spawn_dodge_particles(at_position: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.position = at_position
	p.amount = 28
	p.lifetime = 0.55
	p.one_shot = true
	p.explosiveness = 0.95
	p.spread = 80.0
	p.gravity = Vector2(0, -120)
	p.initial_velocity_min = 70.0
	p.initial_velocity_max = 160.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0
	p.color = Color(0.9, 0.95, 1.0, 0.9)
	get_tree().current_scene.add_child(p)
	p.emitting = true
	await get_tree().create_timer(p.lifetime + 0.1).timeout
	if is_instance_valid(p):
		p.queue_free()

## Mantido como alias de sangue para chamadas legadas.
func spawn_impact_particles(at_position: Vector2) -> void:
	_spawn_particles(BLOOD_PARTICLES, at_position)

func _spawn_particles(scene: PackedScene, at_position: Vector2) -> void:
	var particles: CPUParticles2D = scene.instantiate()
	particles.position = at_position
	get_tree().current_scene.add_child(particles)
	particles.emitting = true
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	if is_instance_valid(particles):
		particles.queue_free()
