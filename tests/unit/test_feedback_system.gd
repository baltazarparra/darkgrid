extends GutTest

var _fx: FeedbackSystem

func before_each():
	_fx = FeedbackSystem.new()
	add_child_autofree(_fx)

func test_pools_prebuilt_on_ready() -> void:
	# 8 tipos × POOL_PER_KIND emissores, todos pré-instanciados e parados
	assert_eq(_fx.get_child_count(), 8 * FeedbackSystem.POOL_PER_KIND)
	for child in _fx.get_children():
		var emitter := child as CPUParticles2D
		assert_not_null(emitter)
		assert_true(emitter.one_shot, "%s deve ser one_shot" % emitter.name)
		assert_eq(emitter.z_index, FeedbackSystem.PARTICLES_Z)

func test_hit_path_allocates_no_nodes() -> void:
	var before: int = _fx.get_child_count()
	_fx.spawn_critical_particles(Vector2(10, 10))
	_fx.spawn_death_particles(Vector2(10, 10))
	_fx.spawn_blood_particles(Vector2.ZERO)
	_fx.spawn_dodge_particles(Vector2.ZERO)
	_fx.spawn_fail_particles(Vector2.ZERO)
	_fx.spawn_bubble_burst(Vector2.ZERO, Color.RED)
	_fx.spawn_impact_particles(Vector2.ZERO)
	assert_eq(_fx.get_child_count(), before, "caminho do hit não pode instanciar nó")

func test_fire_positions_and_restarts() -> void:
	_fx.spawn_blood_particles(Vector2(33, 44))
	var blood: CPUParticles2D = _fx._pools["blood"][0]
	assert_eq(blood.position, Vector2(33, 44))
	assert_true(blood.emitting)

func test_round_robin_steals_oldest() -> void:
	_fx.spawn_blood_particles(Vector2(1, 0))
	_fx.spawn_blood_particles(Vector2(2, 0))
	_fx.spawn_blood_particles(Vector2(3, 0))
	# POOL_PER_KIND=2: o terceiro disparo rouba o emissor mais antigo
	assert_eq((_fx._pools["blood"][0] as CPUParticles2D).position, Vector2(3, 0))
	assert_eq((_fx._pools["blood"][1] as CPUParticles2D).position, Vector2(2, 0))

func test_bubble_burst_applies_tint() -> void:
	_fx.spawn_bubble_burst(Vector2.ZERO, Color.RED)
	assert_eq((_fx._pools["bubble"][0] as CPUParticles2D).color, Color.RED)

func test_additive_material_is_shared_single_instance() -> void:
	var spark: CPUParticles2D = _fx._pools["spark"][0]
	var dodge: CPUParticles2D = _fx._pools["dodge"][0]
	assert_eq(spark.material, dodge.material)
	assert_eq(spark.material, FeedbackSystem.ADDITIVE_MATERIAL)

func test_fail_particles_have_no_glow() -> void:
	# Leitura "morta" da falha: blend normal, sem brilho — tom não negocia
	assert_null((_fx._pools["fail"][0] as CPUParticles2D).material)

func test_blood_keeps_double_gore_density() -> void:
	var blood: CPUParticles2D = _fx._pools["blood"][0]
	var impact: CPUParticles2D = _fx._pools["impact"][0]
	assert_eq(blood.amount, impact.amount * 2, "golpe espirra o dobro do sangue base")

func test_blood_spilled_signal_still_feeds_decals() -> void:
	watch_signals(_fx)
	_fx.spawn_death_particles(Vector2(7, 7))
	assert_signal_emitted_with_parameters(_fx, "blood_spilled", [Vector2(7, 7), 2.6])
