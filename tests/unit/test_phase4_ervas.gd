extends GutTest

## Tier 4 das ervas (recompensa de Fase 4): Breu-Ancestral (forca_4, +2 dano) e
## Coração-de-Cerne (saude_4, +2 HP). Gating por `requires` (tier 3 da mesma linha) e
## matemática dos bônus. Também valida que UPGRADE_DEFS tem os metadados de UI e que os
## ícones existem no disco.

var _original_save_path: String

func before_each() -> void:
	_original_save_path = MetaProgression.SAVE_PATH
	MetaProgression.SAVE_PATH = "user://test_phase4_savegame.json"
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

func test_forca4_requires_forca3() -> void:
	MetaProgression.fragments = 10.0
	assert_false(MetaProgression.purchase_upgrade("forca_4"), "sem forca_3, rejeita")
	assert_eq(MetaProgression.get_upgrade_level("forca_4"), 0)

func test_saude4_requires_saude3() -> void:
	MetaProgression.fragments = 15.0
	assert_false(MetaProgression.purchase_upgrade("saude_4"), "sem saude_3, rejeita")
	assert_eq(MetaProgression.get_upgrade_level("saude_4"), 0)

func test_full_furia_chain_damage_bonus() -> void:
	# forca(4) + forca_2(6) + forca_3(8) + forca_4(10) = 28 fragmentos.
	MetaProgression.fragments = 28.0
	assert_true(MetaProgression.purchase_upgrade("forca"))
	assert_true(MetaProgression.purchase_upgrade("forca_2"))
	assert_true(MetaProgression.purchase_upgrade("forca_3"))
	assert_true(MetaProgression.purchase_upgrade("forca_4"), "forca_4 compra com a cadeia completa")
	# Bônus: 1 + 1 + 3 + 2 = 7 (dano total na arena = base 1 + 7 = 8).
	assert_eq(MetaProgression.get_damage_bonus(), 7)

func test_full_cura_chain_health_bonus() -> void:
	# saude(6) + saude_2(9) + saude_3(12) + saude_4(15) = 42 fragmentos.
	MetaProgression.fragments = 42.0
	assert_true(MetaProgression.purchase_upgrade("saude"))
	assert_true(MetaProgression.purchase_upgrade("saude_2"))
	assert_true(MetaProgression.purchase_upgrade("saude_3"))
	assert_true(MetaProgression.purchase_upgrade("saude_4"), "saude_4 compra com a cadeia completa")
	# Cada nível soma +2 HP → 4 níveis = +8.
	assert_eq(MetaProgression.get_health_bonus(), 8)

func test_forca4_persists_through_save_load() -> void:
	MetaProgression.fragments = 28.0
	MetaProgression.purchase_upgrade("forca")
	MetaProgression.purchase_upgrade("forca_2")
	MetaProgression.purchase_upgrade("forca_3")
	MetaProgression.purchase_upgrade("forca_4")
	MetaProgression.save_progress()
	MetaProgression.upgrades = {}
	MetaProgression.load_progress()
	assert_eq(MetaProgression.get_upgrade_level("forca_4"), 1, "forca_4 persiste no save")

func test_defs_have_ui_metadata_and_icons() -> void:
	for key in MetaProgression.UPGRADE_DEFS:
		var def: Dictionary = MetaProgression.UPGRADE_DEFS[key]
		for field in ["name", "line", "tier", "phase", "effect", "icon"]:
			assert_true(def.has(field), "%s tem o campo de UI '%s'" % [key, field])
		assert_true(String(def["line"]) in ["furia", "cura"], "%s.line é furia/cura" % key)
		assert_true(FileAccess.file_exists(String(def["icon"])), "ícone existe: %s" % def["icon"])
