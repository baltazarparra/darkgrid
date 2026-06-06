extends GutTest

# O bruxo dos machados: monstro comum recuperado do antigo boss-caçador. Herda o
# moveset do Caçador, mas é mais forte (14 de vida) e bate +1 por golpe.

func test_bruxo_is_a_cacador_with_stronger_stats() -> void:
	var bruxo = preload("res://scenes/arena/bruxo.tscn").instantiate()
	add_child_autofree(bruxo)
	assert_true(bruxo is Cacador, "Bruxo herda o moveset do Caçador")
	assert_true(bruxo is Criatura, "Bruxo é uma Criatura")
	assert_eq(bruxo.health.max_health, Constants.BRUXO_MAX_HEALTH, "14 de vida")
	assert_almost_eq(bruxo.extra_hit_damage, 1.0, 0.001, "+1 de dano por golpe")
	assert_eq(bruxo.base_attack_damage, 1)

func test_bruxo_uses_cacador_attack_patterns() -> void:
	var bruxo = preload("res://scenes/arena/bruxo.tscn").instantiate()
	add_child_autofree(bruxo)
	# O moveset é o do Caçador: get_attack_pattern só devolve padrões conhecidos.
	var known := [
		Cacador.CACADOR_BASIC_PATTERN,
		Cacador.CACADOR_DOUBLE_PATTERN,
		Cacador.CACADOR_SPECIAL_PATTERN,
	]
	for _i in 30:
		assert_true(bruxo.get_attack_pattern() in known,
			"padrão de ataque do Bruxo é um dos do Caçador")
