class_name Criatura
extends CombatActor

## Inimigo da arena. Possui uma EnemyStateMachine (nó filho) que dirige seu
## ciclo de ataque a partir de um AttackPattern. O ArenaManager apenas escuta.
## O telegraph visual (pulso + lunge) reage aos estados da própria StateMachine.

@export var attack_pattern: AttackPattern
@export var sprite_scale: float = 2.0

@onready var state_machine: EnemyStateMachine = $EnemyStateMachine

var _base_scale: Vector2 = Vector2.ONE
var _base_modulate: Color = Color.WHITE
var _telegraph_tween: Tween
var _home_x: float = 0.0

func _ready() -> void:
	super._ready()
	collision_layer = 1 << (Constants.LAYER_ENEMY - 1)
	collision_mask = 1 << (Constants.LAYER_PLAYER - 1)

	_base_scale = Vector2(sprite_scale, sprite_scale)
	if animated_sprite:
		animated_sprite.scale = _base_scale
		_base_modulate = animated_sprite.modulate  # preserva tom base (ex: Boss)

	if attack_pattern == null:
		attack_pattern = preload("res://resources/attack_patterns/criatura_pattern.tres")

	if state_machine != null:
		state_machine.state_changed.connect(_on_state_changed)
	health.died.connect(_kill_telegraph)

# ─── Telegraph ─────────────────────────────────────
func _on_state_changed(new_state: EnemyStateMachine.State) -> void:
	match new_state:
		EnemyStateMachine.State.WIND_UP:
			_play_windup_telegraph()
		EnemyStateMachine.State.ATTACK:
			_play_attack_lunge()

## Pulso vermelho crescente enquanto o ataque é preparado.
func _play_windup_telegraph() -> void:
	if animated_sprite == null:
		return
	_kill_telegraph()
	_telegraph_tween = create_tween().set_loops()
	_telegraph_tween.tween_property(animated_sprite, "modulate", Color(1.4, 0.4, 0.4), 0.18)
	_telegraph_tween.parallel().tween_property(animated_sprite, "scale", _base_scale * 1.12, 0.18)
	_telegraph_tween.tween_property(animated_sprite, "modulate", _base_modulate, 0.18)
	_telegraph_tween.parallel().tween_property(animated_sprite, "scale", _base_scale, 0.18)

## Lunge curto em direção à Caipora (esquerda) no início do ataque.
func _play_attack_lunge() -> void:
	if animated_sprite == null:
		return
	_kill_telegraph()
	animated_sprite.modulate = _base_modulate
	animated_sprite.scale = _base_scale
	_home_x = position.x
	var lunge := create_tween()
	lunge.tween_property(self, "position:x", _home_x - 80.0, 0.1)
	lunge.tween_property(self, "position:x", _home_x, 0.1)

func _kill_telegraph() -> void:
	if _telegraph_tween != null and _telegraph_tween.is_valid():
		_telegraph_tween.kill()
	if animated_sprite != null:
		animated_sprite.modulate = _base_modulate
		animated_sprite.scale = _base_scale
