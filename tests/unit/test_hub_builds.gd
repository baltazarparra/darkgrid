extends GutTest

## Smoke do Acampamento reescrito: a cena instancia, monta os cards data-driven conforme
## a fase e o cabeçalho do cachimbo, sem erro de runtime.

var _hub: Hub
var _save_path: String

func before_each() -> void:
	_save_path = MetaProgression.SAVE_PATH
	MetaProgression.SAVE_PATH = "user://test_hub_savegame.json"
	MetaProgression.upgrades = {}
	MetaProgression.fragments = 0.0

func after_each() -> void:
	if is_instance_valid(_hub):
		_hub.queue_free()
	if FileAccess.file_exists(MetaProgression.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(MetaProgression.SAVE_PATH))
	MetaProgression.SAVE_PATH = _save_path
	MetaProgression.upgrades = {}
	MetaProgression.fragments = 0.0
	MetaProgression.phase_reached = 1

func _instantiate() -> void:
	_hub = load("res://scenes/ui/hub.tscn").instantiate()
	add_child_autofree(_hub)
	await wait_frames(2)

func test_phase1_shows_only_tier1_cards() -> void:
	MetaProgression.phase_reached = 1
	await _instantiate()
	# Em fase 1 só as ervas tier 1 (forca, saude) têm card.
	assert_true(_hub._cards.has("forca"), "card de Folha-Brasa existe")
	assert_true(_hub._cards.has("saude"), "card de Seiva-Mãe existe")
	assert_false(_hub._cards.has("forca_4"), "tier 4 não aparece na fase 1")
	assert_false(_hub._cards.has("saude_2"), "tier 2 não aparece na fase 1")

func test_phase4_shows_all_cards() -> void:
	MetaProgression.phase_reached = 4
	await _instantiate()
	for key in MetaProgression.UPGRADE_DEFS:
		assert_true(_hub._cards.has(key), "card existe na fase 4: %s" % key)

func test_locked_card_disables_button() -> void:
	MetaProgression.phase_reached = 4
	MetaProgression.fragments = 100.0
	await _instantiate()
	# forca_2 exige forca → bloqueado enquanto forca não comprada.
	var card: Dictionary = _hub._cards["forca_2"]
	var button: Button = card["button"]
	assert_true(button.disabled, "card bloqueado por requisito tem botão desabilitado")
