extends GutTest

# Boss FINAL — Jesuíta Bandeirante Catequizador. O contrato central: seu moveset
# é a UNIÃO de TODOS os padrões de TODOS os chefes, com a mesma chance.

var _jesuita: Jesuita

const CRIATURA  := "res://resources/attack_patterns/criatura_pattern.tres"
const SPECIAL   := "res://resources/attack_patterns/boss_special_pattern.tres"
const DOUBLE    := "res://resources/attack_patterns/boss_double_block_pattern.tres"
const WHITE     := "res://resources/attack_patterns/boitata_white_special_pattern.tres"
const RASTRO    := "res://resources/attack_patterns/rastro_pattern.tres"
const ASSOBIO   := "res://resources/attack_patterns/assobio_pattern.tres"
const SACI_RAST := "res://resources/attack_patterns/saci_rastro_pattern.tres"

const EXPECTED := [CRIATURA, SPECIAL, DOUBLE, WHITE, RASTRO, ASSOBIO, SACI_RAST]

func before_each() -> void:
	_jesuita = preload("res://scenes/arena/jesuita.tscn").instantiate()
	add_child_autofree(_jesuita)

func test_jesuita_inherits_saci_and_boss() -> void:
	assert_true(_jesuita is Saci, "Jesuíta herda de Saci (cadeia de telegraphs)")
	assert_true(_jesuita is Boss, "Jesuíta é um Boss")

func test_jesuita_health_is_44() -> void:
	assert_eq(_jesuita.health.max_health, Constants.JESUITA_MAX_HEALTH)
	assert_eq(Constants.JESUITA_MAX_HEALTH, 44)

func test_get_attack_pattern_always_valid() -> void:
	for _i in 50:
		var p := _jesuita.get_attack_pattern()
		assert_not_null(p)
		assert_true(p is AttackPattern)
		assert_true(p.resource_path in EXPECTED,
			"padrão sorteado é de algum chefe: %s" % p.resource_path)

func test_moveset_is_exactly_the_union_of_all_boss_patterns() -> void:
	# Amostragem ampla: cada um dos 7 padrões aparece (mesma chance) e nada além.
	var seen := {}
	for _i in 700:
		seen[_jesuita.get_attack_pattern().resource_path] = true
	for path: String in EXPECTED:
		assert_true(seen.has(path), "moveset inclui %s" % path)
	assert_eq(seen.size(), EXPECTED.size(),
		"moveset é exatamente a união dos padrões dos chefes (sem extras)")

func test_telegraph_flags_match_chosen_pattern() -> void:
	# Os flags de telegraph batem com o padrão retornado (exclusivos: no máximo um
	# ligado, e o correto para cada padrão) — garante o telegraph certo em cena.
	for _i in 400:
		var path := _jesuita.get_attack_pattern().resource_path
		match path:
			WHITE:
				assert_true(_jesuita._current_is_white_special, "branco → flag branco")
				assert_false(_jesuita._current_is_special)
				assert_false(_jesuita._current_is_rastro)
				assert_false(_jesuita._current_is_assobio)
			SPECIAL:
				assert_true(_jesuita._current_is_special, "especial → flag especial")
				assert_false(_jesuita._current_is_white_special)
			ASSOBIO:
				assert_true(_jesuita._current_is_assobio, "assobio → flag assobio")
			RASTRO, SACI_RAST:
				assert_true(_jesuita._current_is_rastro, "rastro → flag rastro")
			_:
				# CRIATURA / DOUBLE_BLOCK: nenhum flag de telegraph especial.
				assert_false(_jesuita._current_is_special)
				assert_false(_jesuita._current_is_white_special)
				assert_false(_jesuita._current_is_rastro)
				assert_false(_jesuita._current_is_assobio)
