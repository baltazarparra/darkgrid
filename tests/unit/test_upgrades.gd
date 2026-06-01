extends GutTest

var _original_save_path: String

func before_each():
    _original_save_path = MetaProgression.SAVE_PATH
    MetaProgression.SAVE_PATH = "user://test_savegame.json"
    MetaProgression.upgrades = {}

func after_each():
    if FileAccess.file_exists(MetaProgression.SAVE_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(MetaProgression.SAVE_PATH))
    MetaProgression.SAVE_PATH = _original_save_path
    MetaProgression.upgrades = {}

func test_purchase_increments_and_caps():
    assert_true(MetaProgression.purchase_upgrade("max_hp"))
    assert_eq(MetaProgression.get_upgrade_level("max_hp"), 1)
    assert_eq(MetaProgression.get_bonus_max_hp(), 10)
    MetaProgression.purchase_upgrade("max_hp")
    MetaProgression.purchase_upgrade("max_hp")
    assert_false(MetaProgression.purchase_upgrade("max_hp"), "recusa no cap")
    assert_eq(MetaProgression.get_upgrade_level("max_hp"), 3)

func test_unknown_upgrade_is_rejected():
    assert_false(MetaProgression.purchase_upgrade("inexistente"))

func test_upgrades_persist_through_save_load():
    MetaProgression.purchase_upgrade("cooldown")
    MetaProgression.save_progress()
    MetaProgression.upgrades = {}
    MetaProgression.load_progress()
    assert_eq(MetaProgression.get_upgrade_level("cooldown"), 1)
    assert_almost_eq(MetaProgression.get_cooldown_reduction(), 0.1, 0.001)
