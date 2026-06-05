extends GutTest

## Ervas no chão do acampamento (Etapa 2 da Fase 9): o conjunto segue o gate da economia
## (phase_reached + requires + não-comprada) e pisar numa erva compra via purchase_upgrade —
## debitando fragmentos e persistindo. Pisar numa erva cara não compra. Tudo headless.

var _hub: Node2D
var _save_path: String

func before_each() -> void:
	_save_path = MetaProgression.SAVE_PATH
	MetaProgression.SAVE_PATH = "user://test_hub_ervas_savegame.json"
	MetaProgression.upgrades = {}
	MetaProgression.fragments = 0.0
	MetaProgression.phase_reached = 1

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
	_hub = load("res://scenes/hub/hub.tscn").instantiate()
	add_child_autofree(_hub)
	await wait_frames(1)

func _placed_keys() -> Array:
	var out: Array = []
	for pos: Vector2i in _hub._ervas:
		out.append(_hub._ervas[pos].key)
	return out

func _pos_of(key: String) -> Vector2i:
	for pos: Vector2i in _hub._ervas:
		if _hub._ervas[pos].key == key:
			return pos
	return Vector2i(-999, -999)

# ── Fase 1 fresca: só as ervas tier 1 de cada trilha no chão ──
func test_phase1_places_only_tier1_ervas() -> void:
	MetaProgression.phase_reached = 1
	await _instantiate()
	var keys := _placed_keys()
	assert_true("forca" in keys, "Folha-Brasa (forca) no chão")
	assert_true("saude" in keys, "Seiva-Mãe (saude) no chão")
	assert_false("forca_2" in keys, "ervas de fase 2 não aparecem na fase 1")
	assert_eq(keys.size(), 2, "só duas ervas na fase 1 fresca")

# ── requires trava a cadeia: forca_2/3/4 só aparecem com o requisito comprado ──
func test_requires_gate_excludes_locked_chain() -> void:
	MetaProgression.phase_reached = 4
	MetaProgression.upgrades = {}
	await _instantiate()
	var keys := _placed_keys()
	assert_true("forca" in keys, "forca (sem requisito) aparece na fase 4")
	assert_false("forca_2" in keys, "forca_2 travada: requer forca ainda não comprada")
	assert_false("forca_3" in keys, "forca_3 travada na cadeia")

# ── Comprar a forca libera a forca_2 no conjunto disponível (próxima visita) ──
func test_available_unlocks_next_when_requirement_owned() -> void:
	MetaProgression.phase_reached = 4
	MetaProgression.upgrades = {"forca": 1}
	await _instantiate()
	var avail: Array = _hub._available_keys(MetaProgression.FURIA_KEYS)
	assert_false("forca" in avail, "forca já fumada não reaparece")
	assert_true("forca_2" in avail, "forca_2 liberada com forca no cachimbo")

# ── Pisar numa erva acessível compra, debita e some do chão ──
func test_step_buys_affordable_erva() -> void:
	MetaProgression.phase_reached = 1
	MetaProgression.fragments = 100.0
	await _instantiate()
	var pos := _pos_of("forca")
	assert_true(_hub._ervas.has(pos), "forca no chão antes de comprar")
	_hub._on_caipora_moved(pos)
	assert_eq(MetaProgression.get_upgrade_level("forca"), 1, "forca comprada ao pisar")
	assert_eq(MetaProgression.fragments, 96.0, "4 fragmentos debitados (custo da forca)")
	assert_false(_hub._ervas.has(pos), "erva some do chão após a compra")
	assert_eq(MetaProgression.get_damage_bonus(), 1, "bônus de dano reflete a compra")

# ── Pisar numa erva cara não compra e ela permanece ──
func test_step_on_unaffordable_erva_does_not_buy() -> void:
	MetaProgression.phase_reached = 1
	MetaProgression.fragments = 1.0  # < custo 4 da forca
	await _instantiate()
	var pos := _pos_of("forca")
	_hub._on_caipora_moved(pos)
	assert_eq(MetaProgression.get_upgrade_level("forca"), 0, "sem fragmento suficiente não compra")
	assert_eq(MetaProgression.fragments, 1.0, "fragmentos intactos")
	assert_true(_hub._ervas.has(pos), "erva cara permanece no chão")

# ── Ervas ficam fora do caminho direto spawn→saída (não auto-compra ao sair) ──
func test_ervas_off_the_exit_lane() -> void:
	MetaProgression.phase_reached = 4
	await _instantiate()
	for pos: Vector2i in _hub._ervas:
		assert_ne(pos, _hub._exit_pos, "nenhuma erva sobre o rastro de saída")
		assert_ne(pos, _hub._spawn_pos, "nenhuma erva sobre o spawn")
		assert_ne(pos.y, _hub._spawn_pos.y, "ervas fora da linha do meio (escolha do jogador)")
