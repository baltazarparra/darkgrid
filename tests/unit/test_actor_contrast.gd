extends GutTest

func _first_sprite(node: Node) -> Sprite2D:
	for child in node.get_children():
		if child is Sprite2D and child.name != ActorContrast.SHADOW_NAME:
			return child
	return null

func test_map_enemy_gets_shadow_light_and_outline() -> void:
	var enemy := MapEnemy.new()
	add_child_autofree(enemy)
	enemy.setup("e1", Vector2i.ZERO, false, "", Vector2i(-1, -1), "cacador")

	assert_not_null(enemy.get_node_or_null(ActorContrast.SHADOW_NAME),
		"inimigo do mapa nasce com sombra de contato")
	assert_not_null(enemy.get_node_or_null(ActorContrast.FRONT_LIGHT_NAME),
		"inimigo do mapa nasce com luz frontal de contraste")

	var sprite := _first_sprite(enemy)
	assert_not_null(sprite, "inimigo do mapa tem sprite visual")
	assert_true(sprite.material is ShaderMaterial, "sprite recebe outline shader")

func test_actor_contrast_is_idempotent() -> void:
	var owner := Node2D.new()
	add_child_autofree(owner)
	ActorContrast.add_ground_shadow(owner, Vector2.ONE)
	ActorContrast.add_ground_shadow(owner, Vector2(2.0, 0.5))

	var shadows := 0
	for child in owner.get_children():
		if child.name == ActorContrast.SHADOW_NAME:
			shadows += 1
	assert_eq(shadows, 1, "sombra de contraste nao duplica em reapply")
