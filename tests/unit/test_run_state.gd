extends GutTest

var _original_save_path: String

func before_each():
	_original_save_path = MetaProgression.SAVE_PATH
	MetaProgression.SAVE_PATH = "user://test_savegame.json"
	MetaProgression.upgrades = {}
	MetaProgression.fragments = 0
	MetaProgression.total_runs = 0
	MetaProgression.total_wins = 0
	MetaProgression.phase_reached = 1

func after_each():
	if FileAccess.file_exists(MetaProgression.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(MetaProgression.SAVE_PATH))
	MetaProgression.SAVE_PATH = _original_save_path
	MetaProgression.upgrades = {}
	MetaProgression.fragments = 0
	MetaProgression.phase_reached = 1

func test_start_run_fills_hp():
	GameState.start_run()
	assert_eq(GameState.caipora_max_hp, float(Constants.CAIPORA_MAX_HEALTH))
	assert_eq(GameState.caipora_current_hp, GameState.caipora_max_hp)
	assert_true(GameState.run_active)

func test_damage_persists_until_heal():
	GameState.start_run()
	GameState.caipora_current_hp -= 30
	assert_eq(GameState.caipora_current_hp, GameState.caipora_max_hp - 30)
	GameState.heal_to_full()
	assert_eq(GameState.caipora_current_hp, GameState.caipora_max_hp)

func test_heal_to_full_preserves_in_run_max_hp_growth():
	GameState.start_run()
	GameState.caipora_max_hp += Constants.COMMON_KILL_HP_GROWTH
	GameState.caipora_max_hp += Constants.COMMON_KILL_HP_GROWTH
	GameState.caipora_current_hp = 1.0
	GameState.heal_to_full()
	assert_eq(GameState.caipora_max_hp, float(Constants.CAIPORA_MAX_HEALTH) + 1.0)
	assert_eq(GameState.caipora_current_hp, GameState.caipora_max_hp)

func test_heal_to_full_applies_new_meta_hp_if_larger():
	GameState.start_run()
	MetaProgression.upgrades["saude"] = 1
	GameState.heal_to_full()
	assert_eq(GameState.caipora_max_hp, float(Constants.CAIPORA_MAX_HEALTH + 2))
	assert_eq(GameState.caipora_current_hp, GameState.caipora_max_hp)

func test_end_run_updates_stats():
	GameState.end_run(true)
	assert_eq(MetaProgression.total_runs, 1)
	assert_eq(MetaProgression.total_wins, 1)
	assert_eq(MetaProgression.phase_reached, 6)
	GameState.end_run(false)
	assert_eq(MetaProgression.total_runs, 2)
	assert_eq(MetaProgression.total_wins, 1)
	assert_false(GameState.run_active)
