extends GutTest

var _boitata: Boitata

func before_each() -> void:
	_boitata = preload("res://scenes/arena/boitata.tscn").instantiate()
	add_child_autofree(_boitata)

func test_boitata_is_a_boss() -> void:
	assert_true(_boitata is Boss, "Boitata herda de Boss")

func test_boitata_has_correct_health() -> void:
	assert_eq(_boitata.health.max_health, Constants.BOITATA_MAX_HEALTH)
	assert_eq(Constants.BOITATA_MAX_HEALTH, 15)

func test_white_special_pattern_fields() -> void:
	var p := preload("res://resources/attack_patterns/boitata_white_special_pattern.tres")
	assert_eq(p.strike_count, 4)
	assert_true(p.is_special)
	assert_almost_eq(p.damage_multiplier, 3.0, 0.001)
	assert_almost_eq(p.strike_delay, 0.3, 0.001)

func test_white_special_input_sequence() -> void:
	var p := preload("res://resources/attack_patterns/boitata_white_special_pattern.tres")
	assert_eq(p.input_sequence.size(), 4)
	assert_eq(p.input_sequence[0], "ui_up")
	assert_eq(p.input_sequence[1], "ui_up")
	assert_eq(p.input_sequence[2], "ui_down")
	assert_eq(p.input_sequence[3], "ui_down")

func test_white_special_delay_is_0_2s_less_than_purple() -> void:
	var white := preload("res://resources/attack_patterns/boitata_white_special_pattern.tres")
	var purple := preload("res://resources/attack_patterns/boss_special_pattern.tres")
	assert_almost_eq(white.strike_delay, purple.strike_delay - 0.2, 0.001)

func test_get_attack_pattern_returns_valid_pattern() -> void:
	var pattern := _boitata.get_attack_pattern()
	assert_not_null(pattern)
	assert_true(pattern is AttackPattern)
