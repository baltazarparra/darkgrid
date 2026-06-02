extends GutTest

var _original_save_path: String

func before_each():
	_original_save_path = MetaProgression.SAVE_PATH
	MetaProgression.SAVE_PATH = "user://test_savegame.json"
	MetaProgression.upgrades = {}
	MetaProgression.fragments = 0
	MetaProgression.total_runs = 0
	MetaProgression.total_wins = 0

func after_each():
	if FileAccess.file_exists(MetaProgression.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(MetaProgression.SAVE_PATH))
	MetaProgression.SAVE_PATH = _original_save_path
	MetaProgression.upgrades = {}
	MetaProgression.fragments = 0

func test_start_run_fills_hp():
	GameState.start_run()
	assert_eq(GameState.caipora_max_hp, Constants.CAIPORA_MAX_HEALTH)
	assert_eq(GameState.caipora_current_hp, GameState.caipora_max_hp)
	assert_true(GameState.run_active)

func test_damage_persists_until_heal():
	GameState.start_run()
	GameState.caipora_current_hp -= 30
	assert_eq(GameState.caipora_current_hp, GameState.caipora_max_hp - 30)
	GameState.heal_to_full()
	assert_eq(GameState.caipora_current_hp, GameState.caipora_max_hp)

func test_end_run_updates_stats():
	GameState.end_run(true)
	assert_eq(MetaProgression.total_runs, 1)
	assert_eq(MetaProgression.total_wins, 1)
	GameState.end_run(false)
	assert_eq(MetaProgression.total_runs, 2)
	assert_eq(MetaProgression.total_wins, 1)
	assert_false(GameState.run_active)
