extends GutTest

## Tier 4 das ervas (recompensa de Fase 4): Breu-Ancestral (forca_4, +1 dano) e
## Coração-de-Cerne (saude_4, +4 HP). Gating por `requires` (tier 3 da mesma linha) e
## matemática dos bônus (PRD-economia-v2). Também valida que UPGRADE_DEFS tem os metadados
## de UI e que os ícones existem no disco.

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
	# forca(5) + forca_2(10) + forca_3(16) + forca_4(24) = 55 fragmentos.
	MetaProgression.fragments = 55.0
	assert_true(MetaProgression.purchase_upgrade("forca"))
	assert_true(MetaProgression.purchase_upgrade("forca_2"))
	assert_true(MetaProgression.purchase_upgrade("forca_3"))
	assert_true(MetaProgression.purchase_upgrade("forca_4"), "forca_4 compra com a cadeia completa")
	# Tiers 1-4 somam +1 cada → +4 (dano total na arena = base 1 + 4 = 5).
	assert_eq(MetaProgression.get_damage_bonus(), 4)

func test_full_cura_chain_health_bonus() -> void:
	# saude(6) + saude_2(12) + saude_3(20) + saude_4(30) = 68 fragmentos.
	MetaProgression.fragments = 68.0
	assert_true(MetaProgression.purchase_upgrade("saude"))
	assert_true(MetaProgression.purchase_upgrade("saude_2"))
	assert_true(MetaProgression.purchase_upgrade("saude_3"))
	assert_true(MetaProgression.purchase_upgrade("saude_4"), "saude_4 compra com a cadeia completa")
	# Tiers 1-4: incrementos 2/3/3/4 → +12 (HP máx. = base 2 + 12 = 14).
	assert_eq(MetaProgression.get_health_bonus(), 12)

func test_tier5_6_furia_damage_bonus() -> void:
	# Cadeia completa T1-T6: 55 + 36 + 50 = 141 fragmentos. T5/T6 somam +2 cada.
	MetaProgression.fragments = 141.0
	MetaProgression.phase_reached = 6
	MetaProgression.total_wins = 3
	for key in MetaProgression.FURIA_KEYS:
		assert_true(MetaProgression.purchase_upgrade(key), "compra %s" % key)
	# Tiers 1-4: +4; Tiers 5-6: +4; total +8 (dano base 1 + 8 = 9).
	assert_eq(MetaProgression.get_damage_bonus(), 8)

func test_tier5_6_cura_health_bonus() -> void:
	# Cadeia completa T1-T6: 68 + 42 + 58 = 168 fragmentos.
	MetaProgression.fragments = 168.0
	MetaProgression.phase_reached = 6
	MetaProgression.total_wins = 3
	for key in MetaProgression.CURA_KEYS:
		assert_true(MetaProgression.purchase_upgrade(key), "compra %s" % key)
	# Tiers 1-4: +12; T5: +4; T6: +5; total +21 (HP máx. = base 2 + 21 = 23).
	assert_eq(MetaProgression.get_health_bonus(), 21)

func test_forca4_persists_through_save_load() -> void:
	MetaProgression.fragments = 55.0
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
		# "effect" não é mais um campo: o texto é DERIVADO de dmg/hp via effect_text() (KI-006).
		for field in ["name", "line", "tier", "phase", "icon"]:
			assert_true(def.has(field), "%s tem o campo de UI '%s'" % [key, field])
		var line := String(def["line"])
		assert_true(line in ["furia", "cura"], "%s.line é furia/cura" % key)
		# Cada erva tem o campo numérico da sua trilha (fonte única da matemática).
		assert_true(def.has("dmg") if line == "furia" else def.has("hp"),
			"%s tem o campo numérico da trilha (%s)" % [key, line])
		assert_true(FileAccess.file_exists(String(def["icon"])), "ícone existe: %s" % def["icon"])

## effect_text() reflete a matemática real (dmg/hp + total acumulado da trilha) — guarda
## contra a desincronização label↔bônus que originou o KI-006.
func test_effect_text_matches_math() -> void:
	# Fúria: incrementos +1 (T1-T4) e +2 (T5-T6); total acumulado parte do dano base 1.
	assert_eq(MetaProgression.effect_text("forca"), "Dano +1/hit (total 2)")
	assert_eq(MetaProgression.effect_text("forca_3"), "Dano +1/hit (total 4)")
	assert_eq(MetaProgression.effect_text("forca_4"), "Dano +1/hit (total 5)")
	assert_eq(MetaProgression.effect_text("forca_5"), "Dano +2/hit (total 7)")
	assert_eq(MetaProgression.effect_text("forca_6"), "Dano +2/hit (total 9)")
	# Cura: incrementos 2/3/3/4/4/5; total acumulado parte do HP base 2.
	assert_eq(MetaProgression.effect_text("saude"), "+2 HP (total 4)")
	assert_eq(MetaProgression.effect_text("saude_2"), "+3 HP (total 7)")
	assert_eq(MetaProgression.effect_text("saude_4"), "+4 HP (total 14)")
	assert_eq(MetaProgression.effect_text("saude_5"), "+4 HP (total 18)")
	assert_eq(MetaProgression.effect_text("saude_6"), "+5 HP (total 23)")
