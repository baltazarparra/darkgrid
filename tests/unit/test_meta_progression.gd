class_name TestMetaProgression
extends GutTest

# Isola o save real do dev: o autoload carrega user://savegame.json no _ready(), então
# cada teste redireciona SAVE_PATH para um arquivo temporário e zera o estado em memória.
var _original_save_path: String

func before_each():
	_original_save_path = MetaProgression.SAVE_PATH
	MetaProgression.SAVE_PATH = "user://test_savegame.json"
	_reset_state()

func after_each():
	if FileAccess.file_exists(MetaProgression.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(MetaProgression.SAVE_PATH))
	MetaProgression.SAVE_PATH = _original_save_path
	_reset_state()

func _reset_state():
	MetaProgression.unlocked_characters = ["caipora"]
	MetaProgression.unlocked_modifiers = []
	MetaProgression.total_runs = 0
	MetaProgression.total_wins = 0
	MetaProgression.upgrades = {}
	MetaProgression.fragments = 0.0
	MetaProgression.phase_reached = 1
	MetaProgression.touch_controls_mode = "auto"
	MetaProgression.freed_bosses = []
	MetaProgression.spirits_seen = []

func test_save_and_load():
	MetaProgression.total_runs = 5
	MetaProgression.save_progress()
	MetaProgression.total_runs = 0
	MetaProgression.load_progress()
	assert_eq(MetaProgression.total_runs, 5)

func test_default_unlocks():
	assert_eq(MetaProgression.unlocked_characters, ["caipora"])

func test_save_writes_version():
	MetaProgression.save_progress()
	var file := FileAccess.open(MetaProgression.SAVE_PATH, FileAccess.READ)
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	assert_true(data is Dictionary, "save é um objeto JSON")
	assert_eq(int(data.get("version", -1)), MetaProgression.SAVE_VERSION)

func test_round_trip_preserves_fields():
	MetaProgression.fragments = 12.0
	MetaProgression.phase_reached = 3
	MetaProgression.upgrades = {"forca": 1}
	MetaProgression.touch_controls_mode = "never"
	MetaProgression.save_progress()
	_reset_state()
	MetaProgression.load_progress()
	assert_eq(MetaProgression.fragments, 12.0)
	assert_eq(MetaProgression.phase_reached, 3)
	assert_eq(MetaProgression.get_upgrade_level("forca"), 1)
	assert_eq(MetaProgression.touch_controls_mode, "never")

func test_reset_clears_state_and_file():
	MetaProgression.fragments = 9.0
	MetaProgression.phase_reached = 2
	MetaProgression.save_progress()
	assert_true(FileAccess.file_exists(MetaProgression.SAVE_PATH), "arquivo existe antes do reset")
	MetaProgression.reset_save()
	assert_false(FileAccess.file_exists(MetaProgression.SAVE_PATH), "arquivo removido após reset")
	assert_eq(MetaProgression.fragments, 0.0)
	assert_eq(MetaProgression.phase_reached, 1)
	assert_eq(MetaProgression.unlocked_characters, ["caipora"])

func test_corrupt_save_keeps_defaults():
	# Grava lixo no arquivo e garante que o load não derruba/sobrescreve o estado.
	var file := FileAccess.open(MetaProgression.SAVE_PATH, FileAccess.WRITE)
	file.store_string("{lixo nao json")
	file.close()
	MetaProgression.fragments = 7.0  # valor em memória deve sobreviver ao load corrompido
	MetaProgression.load_progress()
	assert_eq(MetaProgression.fragments, 7.0, "load corrompido mantém os defaults em memória")

# ─── Santuário dos Encantados (PRD-santuario-dos-encantados, Etapa 0) ─────────

func test_free_boss_registers_and_persists():
	MetaProgression.free_boss(2)
	assert_true(MetaProgression.is_boss_freed(2), "Boitatá libertado em memória")
	_reset_state()
	MetaProgression.load_progress()
	assert_true(MetaProgression.is_boss_freed(2), "libertação sobrevive ao reload")
	assert_false(MetaProgression.is_boss_freed(1), "Mula segue na fase")

func test_free_boss_is_idempotent_and_sorted():
	MetaProgression.free_boss(3)
	MetaProgression.free_boss(1)
	MetaProgression.free_boss(3)
	assert_eq(MetaProgression.freed_bosses, [1, 3] as Array[int])

func test_free_boss_ignores_jesuita_and_invalid_phases():
	MetaProgression.free_boss(5)   # Jesuíta não é encantado: nunca entra no santuário
	MetaProgression.free_boss(0)
	MetaProgression.free_boss(99)
	assert_eq(MetaProgression.freed_bosses, [] as Array[int])

func test_mark_spirit_seen_requires_freed_boss():
	MetaProgression.mark_spirit_seen(1)
	assert_false(MetaProgression.has_seen_spirit(1), "rito exige encantado libertado")
	MetaProgression.free_boss(1)
	MetaProgression.mark_spirit_seen(1)
	MetaProgression.mark_spirit_seen(1)
	assert_eq(MetaProgression.spirits_seen, [1] as Array[int])
	_reset_state()
	MetaProgression.load_progress()
	assert_true(MetaProgression.has_seen_spirit(1), "rito visto sobrevive ao reload")

## Migração v3→v4: saves veteranos derivam os libertados de phase_reached (boss da fase
## N derrotado ⇒ phase_reached = N+1) e entram com o rito já visto (sem fila de reveals).
func test_migration_v3_derives_freed_from_phase_reached():
	_write_save_json({"version": 3, "phase_reached": 4})
	MetaProgression.load_progress()
	assert_eq(MetaProgression.freed_bosses, [1, 2, 3] as Array[int])
	assert_eq(MetaProgression.spirits_seen, [1, 2, 3] as Array[int])

func test_migration_v3_full_clear_frees_only_encantados():
	_write_save_json({"version": 3, "phase_reached": 6})
	MetaProgression.load_progress()
	assert_eq(MetaProgression.freed_bosses, [1, 2, 3, 4] as Array[int],
		"Jesuíta (P5) fora mesmo no clear total")

func test_migration_v3_fresh_save_frees_nothing():
	_write_save_json({"version": 3, "phase_reached": 1})
	MetaProgression.load_progress()
	assert_eq(MetaProgression.freed_bosses, [] as Array[int])

func test_v4_save_does_not_rederive_from_phase_reached():
	# Em v4 freed_bosses é a verdade: phase_reached alto com lista vazia permanece vazio.
	_write_save_json({"version": 4, "phase_reached": 6, "freed_bosses": [], "spirits_seen": []})
	MetaProgression.load_progress()
	assert_eq(MetaProgression.freed_bosses, [] as Array[int])

func test_load_sanitizes_freed_phases():
	# Floats do JSON viram int; fases inválidas e duplicatas caem fora; ordena.
	_write_save_json({"version": 4, "freed_bosses": [4.0, 5, 2, 2, -1], "spirits_seen": [9]})
	MetaProgression.load_progress()
	assert_eq(MetaProgression.freed_bosses, [2, 4] as Array[int])
	assert_eq(MetaProgression.spirits_seen, [] as Array[int])

func test_reset_save_returns_guardians_to_phases():
	MetaProgression.free_boss(1)
	MetaProgression.mark_spirit_seen(1)
	MetaProgression.reset_save()
	assert_eq(MetaProgression.freed_bosses, [] as Array[int])
	assert_eq(MetaProgression.spirits_seen, [] as Array[int])

func _write_save_json(data: Dictionary) -> void:
	var file := FileAccess.open(MetaProgression.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
