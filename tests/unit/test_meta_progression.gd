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
