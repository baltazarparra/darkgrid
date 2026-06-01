class_name TestMetaProgression
extends GutTest

func test_save_and_load():
	MetaProgression.total_runs = 5
	MetaProgression.save_progress()
	MetaProgression.total_runs = 0
	MetaProgression.load_progress()
	assert_eq(MetaProgression.total_runs, 5)

func test_default_unlocks():
	assert_eq(MetaProgression.unlocked_characters, ["caipora"])
