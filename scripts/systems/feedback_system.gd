class_name FeedbackSystem
extends Node

const BLOOD_PARTICLES := preload("res://scenes/shared/blood_particles.tscn")
const CRITICAL_PARTICLES := preload("res://scenes/shared/critical_particles.tscn")
const DEATH_PARTICLES := preload("res://scenes/shared/death_particles.tscn")

## Material aditivo compartilhado do projeto. Um único recurso: instâncias
## idênticas de CanvasItemMaterial quebram o batching do Compatibility e
## alocavam a cada golpe (PLANO-performance-60fps §4, G2/G9).
const ADDITIVE_MATERIAL := preload("res://resources/materials/additive_glow.tres")

## Pool de emissores pré-instanciados no _ready: o caminho do hit não pode
## alocar nó nem material (o spike caía exatamente no frame do impacto, junto
## de hit-stop + screenshake). 2 por tipo cobre bursts sobrepostos (crítico +
## morte no mesmo golpe); esgotado, rouba o mais antigo — com lifetimes de
## 0.4-1.2s o burst roubado já está praticamente concluído.
const POOL_PER_KIND: int = 2
## Acima dos atores (z 0, como os bursts avulsos desenhavam ao entrar por
## último na cena), abaixo das bolhas de timing (z 10).
const PARTICLES_Z: int = 5

# ─── Signals ───────────────────────────────────────
signal hit_stop_started(duration: float)
signal hit_stop_ended
## Sangue derramado em `at_position` (intensity: 1.0 golpe, 1.6 crítico,
## 2.6 morte). Consumido por BloodDecals para manchas persistentes no chão.
signal blood_spilled(at_position: Vector2, intensity: float)

@export var shake_intensity: float = 8.0
@export var shake_duration: float = 0.3

var _hit_stop_active: bool = false
var _pools: Dictionary = {}        # kind: String -> Array[CPUParticles2D]
var _pool_cursor: Dictionary = {}  # kind: String -> int

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	_build_pools()

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
## Pausa visual por N frames (60fps de referência): congela sprites dos atores e
## bolhas de timing, mas NÃO toca Engine.time_scale — input continua fluindo.
## Anti-acúmulo: hit-stops simultâneos são ignorados se já houver um ativo.
func trigger_hit_stop(frames: int = 3) -> void:
	if _hit_stop_active:
		return
	# Mix reativo: todo impacto pesado abafa música/ambiência por um instante,
	# deixando o SFX do golpe "estourar" — espelha o hit-stop no áudio.
	AudioDirector.duck()
	_hit_stop_active = true
	var duration: float = frames / 60.0
	hit_stop_started.emit(duration)
	await get_tree().create_timer(duration, true, false, true).timeout
	# Resiliente: se o hit-stop já foi encerrado à força (force_clear_hit_stop, ex.
	# na morte do inimigo), não re-emite ended nem mexe no estado já limpo.
	if _hit_stop_active:
		_hit_stop_active = false
		hit_stop_ended.emit()

## Encerra o hit-stop imediatamente (idempotente). Usado ao encerrar o combate para
## garantir que os sprites voltem a animar (speed_scale=1) antes de qualquer transição,
## sem depender do timer interno do hit-stop em andamento.
func force_clear_hit_stop() -> void:
	if not _hit_stop_active:
		return
	_hit_stop_active = false
	hit_stop_ended.emit()

# ─── Partículas ────────────────────────────────────
func spawn_blood_particles(at_position: Vector2) -> void:
	blood_spilled.emit(at_position, 1.0)
	_fire("blood", at_position)

func spawn_critical_particles(at_position: Vector2) -> void:
	blood_spilled.emit(at_position, 1.6)
	_fire("critical", at_position)
	# Segundo burst: faíscas claras overbright (blend aditivo) por cima do sangue,
	# para a leitura do acerto crítico "estourar" e ficar nítida.
	_fire("spark", at_position)

func spawn_death_particles(at_position: Vector2) -> void:
	blood_spilled.emit(at_position, 2.6)
	_fire("death", at_position)

func spawn_dodge_particles(at_position: Vector2) -> void:
	_fire("dodge", at_position)

## Estouro radial na posição da bolha no acerto — nasce onde o olho do jogador está,
## reforçando a leitura do timing. Aditivo (glow) na cor do contexto.
func spawn_bubble_burst(at_position: Vector2, tint: Color) -> void:
	var burst := _next("bubble")
	burst.position = at_position
	burst.color = tint
	burst.restart()

## Estilhaço negativo do erro: partículas escuras dessaturadas, blend normal (sem
## brilho — leitura "morta") que despencam e dispersam rápido.
func spawn_fail_particles(at_position: Vector2) -> void:
	_fire("fail", at_position)

## Mantido como alias de sangue para chamadas legadas (densidade base, sem o
## dobro do golpe).
func spawn_impact_particles(at_position: Vector2) -> void:
	_fire("impact", at_position)

# ─── Pool ──────────────────────────────────────────
func _fire(kind: String, at_position: Vector2) -> void:
	var emitter := _next(kind)
	emitter.position = at_position
	emitter.restart()

func _next(kind: String) -> CPUParticles2D:
	var pool: Array = _pools[kind]
	var idx: int = _pool_cursor[kind]
	_pool_cursor[kind] = (idx + 1) % pool.size()
	return pool[idx]

func _build_pools() -> void:
	# Densidades preservadas do tom gore: golpe espirra o DOBRO do sangue base
	# da cena; crítico idem.
	_register("blood", func() -> CPUParticles2D: return _from_scene(BLOOD_PARTICLES, 2.0))
	_register("impact", func() -> CPUParticles2D: return _from_scene(BLOOD_PARTICLES, 1.0))
	_register("critical", func() -> CPUParticles2D: return _from_scene(CRITICAL_PARTICLES, 2.0))
	_register("death", func() -> CPUParticles2D: return _from_scene(DEATH_PARTICLES, 1.0))
	_register("spark", _build_spark)
	_register("dodge", _build_dodge)
	_register("bubble", _build_bubble_burst)
	_register("fail", _build_fail)

func _register(kind: String, builder: Callable) -> void:
	var pool: Array[CPUParticles2D] = []
	for i in POOL_PER_KIND:
		var emitter: CPUParticles2D = builder.call()
		emitter.emitting = false
		emitter.z_index = PARTICLES_Z
		add_child(emitter)
		pool.append(emitter)
	_pools[kind] = pool
	_pool_cursor[kind] = 0

func _from_scene(scene: PackedScene, amount_scale: float) -> CPUParticles2D:
	var particles: CPUParticles2D = scene.instantiate()
	if amount_scale != 1.0:
		particles.amount = int(particles.amount * amount_scale)
	return particles

func _build_spark() -> CPUParticles2D:
	var spark := CPUParticles2D.new()
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
	spark.material = ADDITIVE_MATERIAL
	return spark

func _build_dodge() -> CPUParticles2D:
	var p := CPUParticles2D.new()
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
	p.material = ADDITIVE_MATERIAL
	return p

func _build_bubble_burst() -> CPUParticles2D:
	var p := CPUParticles2D.new()
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
	p.material = ADDITIVE_MATERIAL
	return p

func _build_fail() -> CPUParticles2D:
	var p := CPUParticles2D.new()
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
	return p
