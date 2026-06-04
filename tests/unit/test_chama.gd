extends GutTest

# Cobre a CHAMA (elemento fogo): sorteio a cada 10 mortes após a espada (forca_3),
# +CHAMA_DAMAGE_BONUS de dano e persistência. Espelha o isolamento de test_upgrades.gd.

var _original_save_path: String
var _original_chance: float

func before_each():
	_original_save_path = MetaProgression.SAVE_PATH
	_original_chance = MetaProgression.CHAMA_DROP_CHANCE
	MetaProgression.SAVE_PATH = "user://test_savegame.json"
	MetaProgression.upgrades = {}
	MetaProgression.fragments = 0
	MetaProgression.phase_reached = 1
	MetaProgression.has_chama = false
	MetaProgression.kills_toward_chama = 0

func after_each():
	if FileAccess.file_exists(MetaProgression.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(MetaProgression.SAVE_PATH))
	MetaProgression.SAVE_PATH = _original_save_path
	MetaProgression.CHAMA_DROP_CHANCE = _original_chance
	MetaProgression.upgrades = {}
	MetaProgression.fragments = 0
	MetaProgression.phase_reached = 1
	MetaProgression.has_chama = false
	MetaProgression.kills_toward_chama = 0

# ─── Dano ──────────────────────────────────────────
func test_chama_adds_damage_bonus():
	MetaProgression.upgrades = {"forca_3": 1}
	var without_chama := MetaProgression.get_damage_bonus()
	MetaProgression.has_chama = true
	assert_eq(MetaProgression.get_damage_bonus(),
		without_chama + MetaProgression.CHAMA_DAMAGE_BONUS,
		"CHAMA soma CHAMA_DAMAGE_BONUS ao dano")

# ─── Gate da espada ────────────────────────────────
func test_no_roll_without_sword():
	# Sem forca_3 a morte não conta para a CHAMA.
	assert_false(MetaProgression.register_kill_for_chama())
	assert_eq(MetaProgression.kills_toward_chama, 0)

# ─── Contador + sorteio ────────────────────────────
func test_counter_increments_until_tenth_kill():
	MetaProgression.upgrades = {"forca_3": 1}
	MetaProgression.CHAMA_DROP_CHANCE = 0.0  # sorteio sempre falha
	for i in range(MetaProgression.KILLS_PER_CHAMA_ROLL - 1):
		assert_false(MetaProgression.register_kill_for_chama(), "antes do 10º não sorteia")
	assert_eq(MetaProgression.kills_toward_chama, MetaProgression.KILLS_PER_CHAMA_ROLL - 1)
	# 10ª morte: sorteia e falha → contador zera, CHAMA não obtida.
	assert_false(MetaProgression.register_kill_for_chama())
	assert_false(MetaProgression.has_chama)
	assert_eq(MetaProgression.kills_toward_chama, 0)

func test_guaranteed_chama_on_tenth_kill():
	MetaProgression.upgrades = {"forca_3": 1}
	MetaProgression.CHAMA_DROP_CHANCE = 1.0  # sorteio sempre ganha
	var won := false
	for i in range(MetaProgression.KILLS_PER_CHAMA_ROLL):
		won = MetaProgression.register_kill_for_chama()
	assert_true(won, "10ª morte com chance 1.0 conquista a CHAMA")
	assert_true(MetaProgression.has_chama)
	assert_eq(MetaProgression.kills_toward_chama, 0)

func test_stops_counting_after_chama():
	MetaProgression.upgrades = {"forca_3": 1}
	MetaProgression.has_chama = true
	assert_false(MetaProgression.register_kill_for_chama(), "com CHAMA já obtida não conta")
	assert_eq(MetaProgression.kills_toward_chama, 0)

# ─── Persistência ──────────────────────────────────
func test_chama_persists_through_save_load():
	MetaProgression.has_chama = true
	MetaProgression.kills_toward_chama = 4
	MetaProgression.save_progress()
	MetaProgression.has_chama = false
	MetaProgression.kills_toward_chama = 0
	MetaProgression.load_progress()
	assert_true(MetaProgression.has_chama)
	assert_eq(MetaProgression.kills_toward_chama, 4)
