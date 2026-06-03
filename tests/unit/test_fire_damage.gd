extends GutTest

func test_fire_tile_damage_constant_is_2() -> void:
	assert_eq(Constants.FIRE_TILE_DAMAGE, 2)

func test_fire_tile_damage_reduces_hp_by_2() -> void:
	GameState.start_run()
	var hp_before: float = GameState.caipora_current_hp
	GameState.caipora_current_hp = maxi(0, GameState.caipora_current_hp - Constants.FIRE_TILE_DAMAGE)
	assert_eq(GameState.caipora_current_hp, hp_before - 2.0)

func test_fire_tile_damage_does_not_go_below_zero() -> void:
	GameState.caipora_current_hp = 1.0
	GameState.caipora_current_hp = maxi(0, GameState.caipora_current_hp - Constants.FIRE_TILE_DAMAGE)
	assert_eq(GameState.caipora_current_hp, 0.0)

func test_fire_damage_greater_than_phase1_hazard() -> void:
	assert_gt(Constants.FIRE_TILE_DAMAGE, 1, "Fase 2: fogo faz mais dano que hazard da Fase 1")
