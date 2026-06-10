extends GutTest

# Pool de partículas do FeedbackSystem (Fase 10): reuso via restart() em vez de
# instanciar/destruir a cada golpe (alocação no frame do impacto = stutter em
# Android modesto) e densidade reduzida em telefone.

const FeedbackSystemScript := preload("res://scripts/systems/feedback_system.gd")

var _fb: FeedbackSystem
var _scene_stub: Node2D
var _prev_scene: Node

func before_each() -> void:
	# _attach_to_scene pendura partículas na current_scene; headless o GUT roda
	# sem uma — apontamos para um stub e restauramos depois.
	_scene_stub = Node2D.new()
	get_tree().root.add_child(_scene_stub)
	_prev_scene = get_tree().current_scene
	get_tree().current_scene = _scene_stub
	_fb = FeedbackSystemScript.new()
	add_child_autofree(_fb)

func after_each() -> void:
	get_tree().current_scene = _prev_scene
	_scene_stub.queue_free()

# ── Telefone (lado curto < 640) corta a densidade pela metade, tablet não ──
func test_particle_scale_halves_on_phone() -> void:
	assert_eq(Constants.particle_amount_scale(Vector2(393, 852)),
		Constants.PHONE_PARTICLE_SCALE, "telefone retrato")
	assert_eq(Constants.particle_amount_scale(Vector2(852, 393)),
		Constants.PHONE_PARTICLE_SCALE, "telefone paisagem (giro não muda o lado curto)")
	assert_eq(Constants.particle_amount_scale(Vector2(1180, 820)), 1.0, "tablet")
	assert_eq(Constants.particle_amount_scale(Vector2(1920, 1080)), 1.0, "desktop")

# ── O 3º burst reusa o nó do 1º (round-robin de POOL_PER_KEY=2): zero alocação ──
func test_burst_reuses_pooled_nodes() -> void:
	_fb.spawn_fail_particles(Vector2.ZERO)
	_fb.spawn_fail_particles(Vector2.ZERO)
	assert_eq(_scene_stub.get_child_count(), 2, "dois nós no pool após dois bursts")
	var first: CPUParticles2D = _fb._pool[&"fail"][0]
	assert_not_null(first, "primeiro nó do pool existe")
	_fb.spawn_fail_particles(Vector2(10.0, 0.0))
	assert_eq(_scene_stub.get_child_count(), 2, "terceiro burst NÃO cria nó novo")
	assert_eq(_fb._pool[&"fail"][0], first, "round-robin volta ao primeiro nó")
	assert_eq(first.position, Vector2(10.0, 0.0), "reuso reposiciona o mesmo nó")
	assert_true(first.emitting, "restart() reacende a emissão")

# ── Burst tintado (bolha) recolore o nó reusado ──
func test_bubble_burst_tints_pooled_node() -> void:
	_fb.spawn_bubble_burst(Vector2.ZERO, Color.RED)
	var p: CPUParticles2D = _fb._pool[&"bubble"][0]
	assert_eq(p.color, Color.RED, "primeiro tint aplicado")
	_fb.spawn_bubble_burst(Vector2.ZERO, Color.BLUE)
	_fb.spawn_bubble_burst(Vector2.ZERO, Color.GREEN)
	assert_eq(p.color, Color.GREEN, "reuso re-tinta o mesmo nó")

# ── Densidade aplicada na criação respeita a escala do device atual ──
func test_amount_respects_device_scale() -> void:
	_fb.spawn_fail_particles(Vector2.ZERO)
	var p: CPUParticles2D = _fb._pool[&"fail"][0]
	var vp: Vector2 = _fb.get_viewport().get_visible_rect().size
	var expected: int = maxi(1, int(22.0 * Constants.particle_amount_scale(vp)))
	assert_eq(p.amount, expected, "amount do fail escalado pela classe do device")
