class_name Criatura
extends CombatActor

func _ready() -> void:
	super._ready()
	collision_layer = 1 << (Constants.LAYER_ENEMY - 1)
	collision_mask = 1 << (Constants.LAYER_PLAYER - 1)

	if animated_sprite:
		animated_sprite.scale = Vector2(2, 2)
