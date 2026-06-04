class_name Saci
extends Curupira

## Boss Final — Fase 4: Saci Pererê. A casa arde; ele já não pertence a ela.
##
## Mesmo kit do Curupira, com uma diferença no rastro: janela de ação 0.1s menor
## e intervalo entre hits 0.2s menor (SACI_RASTRO_PATTERN). Tema de fogo — carapuça
## vermelha, brasas — refletido no telegraph e na aura.

const SACI_RASTRO_PATTERN := preload("res://resources/attack_patterns/saci_rastro_pattern.tres")

func get_attack_pattern() -> AttackPattern:
	var r := randf()
	var chosen: AttackPattern
	_current_is_rastro = false
	_current_is_assobio = false
	_current_is_special = false

	if r < RASTRO_CHANCE:
		_current_is_rastro = true
		chosen = SACI_RASTRO_PATTERN
	elif r < RASTRO_CHANCE + ASSOBIO_CHANCE:
		_current_is_assobio = true
		chosen = ASSOBIO_PATTERN
	else:
		var r2 := randf()
		if r2 < 0.333:
			_current_is_special = true
			chosen = SPECIAL_PATTERN
		elif r2 < 0.666:
			chosen = DOUBLE_BLOCK_PATTERN
		else:
			chosen = CRIATURA_PATTERN
	_active_pattern = chosen
	return chosen

func _play_windup_telegraph() -> void:
	if animated_sprite == null:
		return
	if _current_is_assobio:
		_kill_telegraph()
		_play_double_jump_telegraph()
		return
	if _current_is_rastro:
		_kill_telegraph()
		_telegraph_tween = create_tween().set_loops()
		_telegraph_tween.tween_property(animated_sprite, "modulate", Constants.COLOR_TELEGRAPH_SACI, 0.22)
		_telegraph_tween.parallel().tween_property(animated_sprite, "scale", _base_scale * 1.10, 0.22)
		_telegraph_tween.tween_property(animated_sprite, "modulate", _base_modulate, 0.22)
		_telegraph_tween.parallel().tween_property(animated_sprite, "scale", _base_scale, 0.22)
		return
	super._play_windup_telegraph()

func _play_double_jump_telegraph() -> void:
	var home_y := position.y
	_telegraph_tween = create_tween()
	# Salto 1
	_telegraph_tween.tween_property(self, "position:y", home_y - 40.0, 0.12)
	_telegraph_tween.parallel().tween_property(animated_sprite, "modulate", Constants.COLOR_TELEGRAPH_SACI, 0.12)
	_telegraph_tween.tween_property(self, "position:y", home_y, 0.10)
	_telegraph_tween.parallel().tween_property(animated_sprite, "modulate", _base_modulate, 0.10)
	_telegraph_tween.tween_interval(0.06)
	# Salto 2
	_telegraph_tween.tween_property(self, "position:y", home_y - 40.0, 0.12)
	_telegraph_tween.parallel().tween_property(animated_sprite, "modulate", Constants.COLOR_TELEGRAPH_SACI, 0.12)
	_telegraph_tween.tween_property(self, "position:y", home_y, 0.10)
	_telegraph_tween.parallel().tween_property(animated_sprite, "modulate", _base_modulate, 0.10)

func _spawn_shadow_aura() -> void:
	var aura := CPUParticles2D.new()
	aura.amount = 26
	aura.lifetime = 1.8
	aura.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	aura.emission_sphere_radius = 30.0
	aura.gravity = Vector2(0, -16)
	aura.initial_velocity_min = 4.0
	aura.initial_velocity_max = 12.0
	aura.scale_amount_min = 2.5
	aura.scale_amount_max = 6.0
	aura.color = Constants.COLOR_AURA_SACI
	aura.z_index = -1
	add_child(aura)
