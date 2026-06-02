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
	# Decai com ease-out exponencial: tranco forte que assenta rápido (soco que
	# acomoda), em vez de cair linearmente.
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
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
	# Mix reativo: todo impacto pesado abafa música/ambiência por um instante,
	# deixando o SFX do golpe "estourar" — espelha o hit-stop no áudio.
	AudioDirector.duck()
	_hit_stop_active = true
	Engine.time_scale = 0.0
	await get_tree().create_timer(frames / 60.0, true, false, true).timeout
	Engine.time_scale = 1.0
	_hit_stop_active = false

# ─── Partículas ────────────────────────────────────
func spawn_blood_particles(at_position: Vector2) -> void:
	# Dobro da densidade base: o golpe espirra muito mais sangue (tom gore).
	_spawn_particles(BLOOD_PARTICLES, at_position, 2.0)

func spawn_critical_particles(at_position: Vector2) -> void:
	_spawn_particles(CRITICAL_PARTICLES, at_position, 2.0)
	# Segundo burst: faíscas claras overbright (blend aditivo) por cima do sangue,
	# para a leitura do acerto crítico "estourar" e ficar nítida. Mais densa e
	# violenta que o sangue base.
	var spark := CPUParticles2D.new()
	spark.position = at_position
	spark.amount = 28
	spark.lifetime = 0.4
	spark.one_shot = true
	spark.explosiveness = 1.0
	spark.direction = Vector2(0, -1)
	spark.spread = 180.0
	spark.gravity = Vector2(0, 60)
	spark.initial_velocity_min = 220.0
	spark.initial_velocity_max = 480.0
	spark.scale_amount_min = 2.0
	spark.scale_amount_max = 5.0
	spark.color = Constants.COLOR_PARTICLE_SPARK
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	spark.material = glow
	get_tree().current_scene.add_child(spark)
	spark.emitting = true
	await get_tree().create_timer(spark.lifetime + 0.1).timeout
	if is_instance_valid(spark):
		spark.queue_free()

func spawn_death_particles(at_position: Vector2) -> void:
	_spawn_particles(DEATH_PARTICLES, at_position)

func spawn_dodge_particles(at_position: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.position = at_position
	p.amount = 50
	p.lifetime = 0.6
	p.one_shot = true
	p.explosiveness = 1.0
	# Spread estreito + blend aditivo: vira um "flash" de alívio limpo, não uma
	# nuvem dispersa — leitura clara da esquiva perfeita.
	p.spread = 45.0
	p.gravity = Vector2(0, -120)
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 280.0
	p.scale_amount_min = 2.5
	p.scale_amount_max = 6.0
	p.color = Constants.COLOR_PARTICLE_DODGE
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = glow
	get_tree().current_scene.add_child(p)
	p.emitting = true
	await get_tree().create_timer(p.lifetime + 0.1).timeout
	if is_instance_valid(p):
		p.queue_free()

## Estouro radial na posição da bolha no acerto — nasce onde o olho do jogador está,
## reforçando a leitura do timing. Aditivo (glow) na cor do contexto.
func spawn_bubble_burst(at_position: Vector2, tint: Color) -> void:
	var p := CPUParticles2D.new()
	p.position = at_position
	p.amount = 32
	p.lifetime = 0.45
	p.one_shot = true
	p.explosiveness = 1.0
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 160.0
	p.initial_velocity_max = 360.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 4.0
	p.color = tint
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = glow
	get_tree().current_scene.add_child(p)
	p.emitting = true
	await get_tree().create_timer(p.lifetime + 0.1).timeout
	if is_instance_valid(p):
		p.queue_free()

## Estilhaço negativo do erro: partículas escuras dessaturadas, blend normal (sem
## brilho — leitura "morta") que despencam e dispersam rápido. Comunica a falha sem
## premiar o jogador.
func spawn_fail_particles(at_position: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.position = at_position
	p.amount = 22
	p.lifetime = 0.4
	p.one_shot = true
	p.explosiveness = 1.0
	p.spread = 180.0
	p.gravity = Vector2(0, 320)
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 220.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.color = Constants.COLOR_PARTICLE_FAIL
	get_tree().current_scene.add_child(p)
	p.emitting = true
	await get_tree().create_timer(p.lifetime + 0.1).timeout
	if is_instance_valid(p):
		p.queue_free()

## Mantido como alias de sangue para chamadas legadas.
func spawn_impact_particles(at_position: Vector2) -> void:
	_spawn_particles(BLOOD_PARTICLES, at_position)

func _spawn_particles(scene: PackedScene, at_position: Vector2, amount_scale: float = 1.0) -> void:
	var particles: CPUParticles2D = scene.instantiate()
	particles.position = at_position
	if amount_scale != 1.0:
		particles.amount = int(particles.amount * amount_scale)
	get_tree().current_scene.add_child(particles)
	particles.emitting = true
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	if is_instance_valid(particles):
		particles.queue_free()
