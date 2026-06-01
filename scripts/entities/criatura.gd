class_name Criatura
extends CombatActor

## Inimigo da arena. Possui uma EnemyStateMachine (nó filho) que dirige seu
## ciclo de ataque a partir de um AttackPattern. O ArenaManager apenas escuta.

@export var attack_pattern: AttackPattern

@onready var state_machine: EnemyStateMachine = $EnemyStateMachine

func _ready() -> void:
	super._ready()
	collision_layer = 1 << (Constants.LAYER_ENEMY - 1)
	collision_mask = 1 << (Constants.LAYER_PLAYER - 1)

	if animated_sprite:
		animated_sprite.scale = Vector2(2, 2)

	if attack_pattern == null:
		attack_pattern = preload("res://resources/attack_patterns/criatura_pattern.tres")
