class_name Jesuita
extends Saci

## Boss FINAL — Fase 5: Jesuíta Bandeirante Catequizador.
## "converti todos eles com espelhos e água benta. a floresta pertence ao vaticano."
##
## Moveset = a UNIÃO de TODOS os padrões de TODOS os chefes, com a MESMA chance
## (1/7 cada). O endurecimento da fase (janela −0.2s ALÉM da Fase 4, +1 hit de
## dano) NÃO vive aqui — é da Fase 5 (Constants.PHASE5_*), aplicado igualmente a
## ele e aos 4 chefes-monstro convertidos. Por isso "o mesmo comportamento".
##
## Herda de Saci toda a cadeia de telegraphs (rastro/assobio/salto-duplo +
## especial roxo do Boss). O único padrão fora dessa cadeia é o branco do
## Boitatá (WHITE_SPECIAL_PATTERN), redeclarado aqui com seu próprio flag.

const WHITE_SPECIAL_PATTERN := preload("res://resources/attack_patterns/boitata_white_special_pattern.tres")

var _current_is_white_special: bool = false

func get_attack_pattern() -> AttackPattern:
	# Zera todos os flags de telegraph antes de sortear.
	_current_is_special = false
	_current_is_rastro = false
	_current_is_assobio = false
	_current_is_white_special = false

	# Todos os padrões de todos os chefes, com a MESMA chance (uniforme).
	var pool: Array[AttackPattern] = [
		CRIATURA_PATTERN,        # base (Criatura/Boss)
		SPECIAL_PATTERN,         # Boss (especial roxo)
		DOUBLE_BLOCK_PATTERN,    # Boss (bloqueio duplo)
		WHITE_SPECIAL_PATTERN,   # Boitatá (↑↑↓↓)
		RASTRO_PATTERN,          # Curupira (←→←→)
		ASSOBIO_PATTERN,         # Curupira (janela mínima, 3×)
		SACI_RASTRO_PATTERN,     # Saci (rastro acelerado)
	]
	var idx := randi() % pool.size()
	match idx:
		1: _current_is_special = true
		3: _current_is_white_special = true
		4: _current_is_rastro = true
		5: _current_is_assobio = true
		6: _current_is_rastro = true  # rastro do Saci reusa o telegraph de rastro
	_active_pattern = pool[idx]
	return _active_pattern

func _play_windup_telegraph() -> void:
	if animated_sprite == null:
		return
	# O branco do Boitatá é o único telegraph fora da cadeia herdada do Saci.
	if _current_is_white_special:
		SignalBus.boss_special_telegraph.emit("jesuita")  # sibilo de água benta
		_kill_telegraph()
		_telegraph_tween = create_tween().set_loops()
		_telegraph_tween.tween_property(animated_sprite, "modulate", Constants.COLOR_TELEGRAPH_JESUITA, 0.22)
		_telegraph_tween.parallel().tween_property(animated_sprite, "scale", _base_scale * 1.10, 0.22)
		_telegraph_tween.tween_property(animated_sprite, "modulate", _base_modulate, 0.22)
		_telegraph_tween.parallel().tween_property(animated_sprite, "scale", _base_scale, 0.22)
		return
	super._play_windup_telegraph()

func _spawn_shadow_aura() -> void:
	# Fumaça de incenso podre subindo — dourado-acinzentado corrompido.
	var aura := CPUParticles2D.new()
	aura.amount = 28
	aura.lifetime = 1.9
	aura.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	aura.emission_sphere_radius = 32.0
	aura.gravity = Vector2(0, -14)
	aura.initial_velocity_min = 3.0
	aura.initial_velocity_max = 11.0
	aura.scale_amount_min = 2.5
	aura.scale_amount_max = 6.0
	aura.color = Constants.COLOR_AURA_JESUITA
	aura.z_index = -1
	add_child(aura)
