extends GutTest

var _original_save_path: String

func before_each() -> void:
	_original_save_path = MetaProgression.SAVE_PATH
	MetaProgression.SAVE_PATH = "user://test_phase2_savegame.json"
	MetaProgression.upgrades = {}
	MetaProgression.fragments = 0.0
	MetaProgression.phase_reached = 1

func after_each() -> void:
	if FileAccess.file_exists(MetaProgression.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(MetaProgression.SAVE_PATH))
	MetaProgression.SAVE_PATH = _original_save_path
	MetaProgression.upgrades = {}
	MetaProgression.fragments = 0.0
	MetaProgression.phase_reached = 1

func test_add_fragments_float_accumulates() -> void:
	MetaProgression.add_fragments(1.5)
	MetaProgression.add_fragments(1.5)
	assert_almost_eq(MetaProgression.fragments, 3.0, 0.001)

func test_add_fragment_compat() -> void:
	MetaProgression.add_fragment()
	assert_almost_eq(MetaProgression.fragments, 1.0, 0.001)

func test_fragment_signal_carries_amount() -> void:
	var received_total: Array = [0.0]
	var received_amount: Array = [0.0]
	SignalBus.fragment_gained.connect(func(t, a): received_total[0] = t; received_amount[0] = a)
	MetaProgression.add_fragments(1.5)
	assert_almost_eq(received_total[0], 1.5, 0.001)
	assert_almost_eq(received_amount[0], 1.5, 0.001)

func test_damage_bonus_sums_both_levels() -> void:
	MetaProgression.fragments = 12.0
	MetaProgression.purchase_upgrade("forca")
	MetaProgression.purchase_upgrade("forca_2")
	assert_eq(MetaProgression.get_damage_bonus(), 2)

func test_health_bonus_sums_both_levels() -> void:
	MetaProgression.fragments = 20.0
	MetaProgression.purchase_upgrade("forca")
	MetaProgression.purchase_upgrade("saude")
	MetaProgression.purchase_upgrade("saude_2")
	assert_eq(MetaProgression.get_health_bonus(), 4)

func test_forca2_requires_forca() -> void:
	MetaProgression.fragments = 6.0
	assert_false(MetaProgression.purchase_upgrade("forca_2"), "sem forca prévia, rejeita")
	assert_eq(MetaProgression.get_upgrade_level("forca_2"), 0)

func test_saude2_has_no_forca_prereq() -> void:
	MetaProgression.fragments = 9.0
	assert_true(MetaProgression.purchase_upgrade("saude_2"), "saude_2 não exige forca")
	assert_eq(MetaProgression.get_upgrade_level("saude_2"), 1)

func test_phase_reached_persists() -> void:
	MetaProgression.phase_reached = 2
	MetaProgression.save_progress()
	MetaProgression.phase_reached = 1
	MetaProgression.load_progress()
	assert_eq(MetaProgression.phase_reached, 2)
