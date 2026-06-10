class_name FeedbackSystem
extends Node

const BLOOD_PARTICLES := preload("res://scenes/shared/blood_particles.tscn")
const CRITICAL_PARTICLES := preload("res://scenes/shared/critical_particles.tscn")
const DEATH_PARTICLES := preload("res://scenes/shared/death_particles.tscn")

# ─── Signals ───────────────────────────────────────
signal hit_stop_started(duration: float)
signal hit_stop_ended
## Sangue derramado em `at_position` (intensity: 1.0 golpe, 1.6 crítico,
## 2.6 morte). Consumido por BloodDecals para manchas persistentes no chão.
signal blood_spilled(at_position: Vector2, intensity: float)

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

# ─── Partículas (pool, Fase 10) ────────────────────
# Cada efeito reusa CPUParticles2D via restart() em vez de instantiate() +
# queue_free() por golpe: a alocação acontecia exatamente no frame do impacto —
# o momento crítico do timing — e era o maior suspeito de stutter em Android
# modesto. POOL_PER_KEY=2 em round-robin: um golpe duplo não mata em voo as
# gotas do golpe anterior. Os nós pertencem à cena ativa e morrem com ela; o
# pool detecta o cache inválido e recria. Em telefone, a densidade cai pela
# metade (Constants.particle_amount_scale) — o gore fica nos decals, que são
# baratos e permanentes.
const POOL_PER_KEY := 2

var _pool: Dictionary = {}       # StringName -> Array[CPUParticles2D]
var _pool_idx: Dictionary = {}   # StringName -> int (round-robin)

func spawn_blood_particles(at_position: Vector2) -> void:
	blood_spilled.emit(at_position, 1.0)
	# Dobro da densidade base: o golpe espirra muito mais sangue (tom gore).
	_burst(&"blood", _scene_factory(BLOOD_PARTICLES, 2.0), at_position)

func spawn_critical_particles(at_position: Vector2) -> void:
	blood_spilled.emit(at_position, 1.6)
	_burst(&"critical", _scene_factory(CRITICAL_PARTICLES, 2.0), at_position)
	# Segundo burst: faíscas claras overbright (blend aditivo) por cima do sangue,
	# para a leitura do acerto crítico "estourar" e ficar nítida.
	_burst(&"spark", _make_spark, at_position)

func spawn_death_particles(at_position: Vector2) -> void:
	blood_spilled.emit(at_position, 2.6)
	_burst(&"death", _scene_factory(DEATH_PARTICLES, 1.0), at_position)

func spawn_dodge_particles(at_position: Vector2) -> void:
	_burst(&"dodge", _make_dodge, at_position)

## Estouro radial na posição da bolha no acerto — nasce onde o olho do jogador está,
## reforçando a leitura do timing. Aditivo (glow) na cor do contexto.
func spawn_bubble_burst(at_position: Vector2, tint: Color) -> void:
	_burst(&"bubble", _make_bubble, at_position, tint)

## Estilhaço negativo do erro: partículas escuras dessaturadas, blend normal (sem
## brilho — leitura "morta") que despencam e dispersam rápido. Comunica a falha sem
## premiar o jogador.
func spawn_fail_particles(at_position: Vector2) -> void:
	_burst(&"fail", _make_fail, at_position)

## Mantido como alias de sangue para chamadas legadas.
func spawn_impact_particles(at_position: Vector2) -> void:
	_burst(&"impact", _scene_factory(BLOOD_PARTICLES, 1.0), at_position)

## Dispara o efeito `key` em `at_position`, criando o nó na primeira vez (ou se o
## cache morreu com a cena anterior). `tint.a > 0` recolore antes do restart.
func _burst(key: StringName, factory: Callable, at_position: Vector2, tint: Color = Color.TRANSPARENT) -> void:
	if not _pool.has(key):
		var fresh: Array = []
		fresh.resize(POOL_PER_KEY)
		_pool[key] = fresh
		_pool_idx[key] = -1
	var nodes: Array = _pool[key]
	var idx: int = (int(_pool_idx[key]) + 1) % POOL_PER_KEY
	_pool_idx[key] = idx
	var p: CPUParticles2D = nodes[idx]
	if not is_instance_valid(p) or not p.is_inside_tree():
		p = factory.call()
		p.one_shot = true
		p.explosiveness = 1.0
		var vp := get_viewport().get_visible_rect().size
		p.amount = maxi(1, int(float(p.amount) * Constants.particle_amount_scale(vp)))
		if not _attach_to_scene(p):
			nodes[idx] = null
			return
		nodes[idx] = p
	p.position = at_position
	if tint.a > 0.0:
		p.color = tint
	p.restart()

## Factory de efeito vindo de cena (.tscn), com escala de densidade própria.
func _scene_factory(scene: PackedScene, amount_scale: float) -> Callable:
	return func() -> CPUParticles2D:
		var p: CPUParticles2D = scene.instantiate()
		if amount_scale != 1.0:
			p.amount = int(p.amount * amount_scale)
		return p

func _make_spark() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 28
	p.lifetime = 0.4
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, 60)
	p.initial_velocity_min = 220.0
	p.initial_velocity_max = 480.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0
	p.color = Constants.COLOR_PARTICLE_SPARK
	p.material = _glow_material()
	return p

# Spread estreito + blend aditivo: vira um "flash" de alívio limpo, não uma
# nuvem dispersa — leitura clara da esquiva perfeita.
func _make_dodge() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 50
	p.lifetime = 0.6
	p.spread = 45.0
	p.gravity = Vector2(0, -120)
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 280.0
	p.scale_amount_min = 2.5
	p.scale_amount_max = 6.0
	p.color = Constants.COLOR_PARTICLE_DODGE
	p.material = _glow_material()
	return p

func _make_bubble() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 32
	p.lifetime = 0.45
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 160.0
	p.initial_velocity_max = 360.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 4.0
	p.material = _glow_material()
	return p

func _make_fail() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 22
	p.lifetime = 0.4
	p.spread = 180.0
	p.gravity = Vector2(0, 320)
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 220.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.color = Constants.COLOR_PARTICLE_FAIL
	return p

func _glow_material() -> CanvasItemMaterial:
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return glow

## Anexa um nó de partículas à cena ativa. Retorna false (e descarta o nó) se a árvore
## ou a cena atual não existir — ex.: durante/depois de uma troca de cena. Evita erro de
## add_child em cena inválida quando a coroutine nasce no meio da transição.
func _attach_to_scene(node: Node) -> bool:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		node.queue_free()
		return false
	tree.current_scene.add_child(node)
	return true
