class_name Curupira
extends Boss

## Boss Final — Fase 3: Curupira, o mais antigo protetor da mata.
## Indiferente e letal. Pés-para-trás. Verde profundo. Sem fogo.
##
## Padrões exclusivos:
##   RASTRO (30%): 4 golpes (←→←→), 2.5x dano — rastros invertidos que confundem.
##   ASSOBIO (20%): 1 golpe pesado, wind-up longo, janela curtíssima, 3x dano.
##   Herdados (50%): distribuídos entre os 3 padrões base do Boss.

const RASTRO_PATTERN  := preload("res://resources/attack_patterns/rastro_pattern.tres")
const ASSOBIO_PATTERN := preload("res://resources/attack_patterns/assobio_pattern.tres")

const RASTRO_CHANCE:  float = 0.30
const ASSOBIO_CHANCE: float = 0.20

var _current_is_rastro: bool = false
var _current_is_assobio: bool = false

func _ready() -> void:
	super._ready()

func get_attack_pattern() -> AttackPattern:
	var r := randf()
	var chosen: AttackPattern
	_current_is_rastro = false
	_current_is_assobio = false
	_current_is_special = false

	if r < RASTRO_CHANCE:
		_current_is_rastro = true
		chosen = RASTRO_PATTERN
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
	if _current_is_rastro or _current_is_assobio:
		_kill_telegraph()
		_telegraph_tween = create_tween().set_loops()
		_telegraph_tween.tween_property(animated_sprite, "modulate", Constants.COLOR_TELEGRAPH_CURUPIRA, 0.22)
		_telegraph_tween.parallel().tween_property(animated_sprite, "scale", _base_scale * 1.10, 0.22)
		_telegraph_tween.tween_property(animated_sprite, "modulate", _base_modulate, 0.22)
		_telegraph_tween.parallel().tween_property(animated_sprite, "scale", _base_scale, 0.22)
		return
	super._play_windup_telegraph()

func _spawn_shadow_aura() -> void:
	var aura := CPUParticles2D.new()
	aura.amount = 24
	aura.lifetime = 2.0
	aura.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	aura.emission_sphere_radius = 32.0
	aura.gravity = Vector2(0, -12)
	aura.initial_velocity_min = 3.0
	aura.initial_velocity_max = 10.0
	aura.scale_amount_min = 2.5
	aura.scale_amount_max = 6.0
	aura.color = Constants.COLOR_AURA_CURUPIRA
	aura.z_index = -1
	add_child(aura)
