class_name Boss
extends Criatura

const DOUBLE_PATTERN := preload("res://resources/attack_patterns/boss_double_pattern.tres")
const SPECIAL_PATTERN := preload("res://resources/attack_patterns/boss_special_pattern.tres")

const SPECIAL_CHANCE: float = 0.35

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	super._ready()
	_spawn_shadow_aura()

# ─── Public API ────────────────────────────────────
func get_attack_pattern() -> AttackPattern:
	if randf() < SPECIAL_CHANCE:
		return SPECIAL_PATTERN
	return DOUBLE_PATTERN

# ─── Telegraph override (roxo em vez de vermelho) ──
func _play_windup_telegraph() -> void:
	if animated_sprite == null:
		return
	_kill_telegraph()
	_telegraph_tween = create_tween().set_loops()
	_telegraph_tween.tween_property(animated_sprite, "modulate", Color(0.5, 0.05, 1.0), 0.22)
	_telegraph_tween.parallel().tween_property(animated_sprite, "scale", _base_scale * 1.08, 0.22)
	_telegraph_tween.tween_property(animated_sprite, "modulate", _base_modulate, 0.22)
	_telegraph_tween.parallel().tween_property(animated_sprite, "scale", _base_scale, 0.22)

# ─── Private helpers ───────────────────────────────
func _spawn_shadow_aura() -> void:
	var aura := CPUParticles2D.new()
	aura.amount = 22
	aura.lifetime = 1.8
	aura.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	aura.emission_sphere_radius = 28.0
	aura.gravity = Vector2(0, -18)
	aura.initial_velocity_min = 4.0
	aura.initial_velocity_max = 12.0
	aura.scale_amount_min = 2.5
	aura.scale_amount_max = 5.0
	aura.color = Color(0.18, 0.0, 0.28, 0.7)
	aura.z_index = -1
	add_child(aura)
