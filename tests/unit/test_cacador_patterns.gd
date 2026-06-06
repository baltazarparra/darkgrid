extends GutTest

var _cacador: Cacador

func before_each() -> void:
	_cacador = preload("res://scenes/arena/cacador.tscn").instantiate()
	add_child_autofree(_cacador)

func test_cacador_is_a_criatura() -> void:
	assert_true(_cacador is Criatura, "Cacador herda de Criatura")

func test_cacador_has_correct_health() -> void:
	# Comuns têm HP uniforme por banda de fase (5 nas fases 1-2); a cena usa o default
	# da banda inicial e o ArenaManager sobrepõe por fase (8 nas fases 3-4).
	assert_eq(_cacador.health.max_health, Constants.COMMON_HEALTH_EARLY)
	assert_eq(Constants.COMMON_HEALTH_EARLY, 5)
	assert_eq(Constants.COMMON_HEALTH_LATE, 8)

func test_special_pattern_fields() -> void:
	var p := preload("res://resources/attack_patterns/cacador_special_pattern.tres")
	assert_eq(p.strike_count, 4)
	assert_true(p.is_special)
	assert_almost_eq(p.damage_multiplier, 2.0, 0.001)
	assert_almost_eq(p.strike_delay, 0.5, 0.001)

func test_special_pattern_input_sequence() -> void:
	var p := preload("res://resources/attack_patterns/cacador_special_pattern.tres")
	assert_eq(p.input_sequence.size(), 4)
	assert_eq(p.input_sequence[0], "ui_up")
	assert_eq(p.input_sequence[1], "ui_down")
	assert_eq(p.input_sequence[2], "ui_up")
	assert_eq(p.input_sequence[3], "ui_down")

func test_get_attack_pattern_returns_valid_pattern() -> void:
	var pattern := _cacador.get_attack_pattern()
	assert_not_null(pattern)
	assert_true(pattern is AttackPattern)
