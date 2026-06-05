extends GutTest

var _original_save_path: String

func before_each():
	_original_save_path = MetaProgression.SAVE_PATH
	MetaProgression.SAVE_PATH = "user://test_savegame.json"
	MetaProgression.upgrades = {}
	MetaProgression.fragments = 0
	MetaProgression.phase_reached = 1

func after_each():
	if FileAccess.file_exists(MetaProgression.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(MetaProgression.SAVE_PATH))
	MetaProgression.SAVE_PATH = _original_save_path
	MetaProgression.upgrades = {}
	MetaProgression.fragments = 0
	MetaProgression.phase_reached = 1

func test_purchase_requires_fragments():
	MetaProgression.fragments = 4  # < custo 5 da forca
	assert_false(MetaProgression.purchase_upgrade("forca"), "rejeita sem fragmentos suficientes")
	assert_eq(MetaProgression.get_upgrade_level("forca"), 0)

func test_purchase_consumes_fragments_and_increments():
	MetaProgression.fragments = 5
	assert_true(MetaProgression.purchase_upgrade("forca"))
	assert_eq(MetaProgression.get_upgrade_level("forca"), 1)
	assert_eq(MetaProgression.fragments, 0)

func test_purchase_caps_at_max_level():
	MetaProgression.fragments = 10
	MetaProgression.purchase_upgrade("forca")
	assert_false(MetaProgression.purchase_upgrade("forca"), "recusa no cap")
	assert_eq(MetaProgression.get_upgrade_level("forca"), 1)

func test_unknown_upgrade_is_rejected():
	assert_false(MetaProgression.purchase_upgrade("inexistente"))

func test_forca_persists_through_save_load():
	MetaProgression.fragments = 5
	MetaProgression.purchase_upgrade("forca")
	MetaProgression.save_progress()
	MetaProgression.upgrades = {}
	MetaProgression.fragments = 0
	MetaProgression.load_progress()
	assert_eq(MetaProgression.get_upgrade_level("forca"), 1)
	assert_eq(MetaProgression.fragments, 0)

func test_add_fragment_accumulates_and_persists():
	MetaProgression.add_fragment()
	MetaProgression.add_fragment()
	assert_eq(MetaProgression.fragments, 2)
	MetaProgression.load_progress()
	assert_eq(MetaProgression.fragments, 2)

func test_get_damage_bonus():
	assert_eq(MetaProgression.get_damage_bonus(), 0)
	MetaProgression.fragments = 5
	MetaProgression.purchase_upgrade("forca")
	assert_eq(MetaProgression.get_damage_bonus(), 1)
