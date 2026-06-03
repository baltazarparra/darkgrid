class_name Boitata
extends Boss

## Boss da Fase 2: Boitatá, serpente de fogo. Reutiliza os três padrões do Boss
## da Fase 1 e adiciona um especial branco (↑↑↓↓) mais rápido e mais letal.

const WHITE_SPECIAL_PATTERN := preload("res://resources/attack_patterns/boitata_white_special_pattern.tres")

const WHITE_SPECIAL_CHANCE: float = 0.25

var _current_is_white_special: bool = false

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	super._ready()

# ─── Public API ────────────────────────────────────
func get_attack_pattern() -> AttackPattern:
	var r := randf()
	var chosen: AttackPattern
	if r < WHITE_SPECIAL_CHANCE:
		_current_is_white_special = true
		_current_is_special = false
		chosen = WHITE_SPECIAL_PATTERN
	else:
		_current_is_white_special = false
		# Distribui o restante (75%) igualmente entre os 3 padrões herdados do Boss.
		# Boss.get_attack_pattern() usa SPECIAL_CHANCE=0.35, DOUBLE=0.30, resto=básico —
		# reescrevemos aqui para manter distribuição uniforme dos 3 (25% cada).
		var r2 := randf()
		if r2 < 0.333:
			_current_is_special = true
			chosen = SPECIAL_PATTERN
		elif r2 < 0.666:
			_current_is_special = false
			chosen = DOUBLE_BLOCK_PATTERN
		else:
			_current_is_special = false
			chosen = CRIATURA_PATTERN
	_active_pattern = chosen
	return chosen

# ─── Telegraph override ─────────────────────────────
func _play_windup_telegraph() -> void:
	if animated_sprite == null:
		return
	if _current_is_white_special:
		_kill_telegraph()
		_telegraph_tween = create_tween().set_loops()
		_telegraph_tween.tween_property(animated_sprite, "modulate", Constants.COLOR_TELEGRAPH_BOITATA_WHITE, 0.22)
		_telegraph_tween.parallel().tween_property(animated_sprite, "scale", _base_scale * 1.08, 0.22)
		_telegraph_tween.tween_property(animated_sprite, "modulate", _base_modulate, 0.22)
		_telegraph_tween.parallel().tween_property(animated_sprite, "scale", _base_scale, 0.22)
		return
	super._play_windup_telegraph()

# ─── Private helpers ───────────────────────────────
func _spawn_shadow_aura() -> void:
	var aura := CPUParticles2D.new()
	aura.amount = 28
	aura.lifetime = 1.4
	aura.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	aura.emission_sphere_radius = 30.0
	aura.gravity = Vector2(0, -22)
	aura.initial_velocity_min = 6.0
	aura.initial_velocity_max = 16.0
	aura.scale_amount_min = 2.5
	aura.scale_amount_max = 5.5
	aura.color = Constants.COLOR_AURA_BOITATA
	aura.z_index = -1
	add_child(aura)
