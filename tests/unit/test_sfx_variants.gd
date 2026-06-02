extends GutTest

# Trava o contrato de variação anti-repetição do SfxSystem:
#   - no _ready, descobre as variantes por convenção de nome (hit.wav -> hit_2/_3)
#   - play() roteia para o bus "SFX"
#   - o round-robin percorre todas as variantes sem repetir em sequência
# Não valida áudio audível (isso é manual), só a lógica de seleção.

const HIT_PATH := "res://assets/audio/sfx/hit.wav"

var _sfx: SfxSystem

func before_each():
	_sfx = SfxSystem.new()
	_sfx.hit_sound = load(HIT_PATH)
	add_child_autofree(_sfx)  # dispara _ready -> _register_variants

func test_discovers_all_three_variants():
	var list: Array = _sfx._variants.get(HIT_PATH, [])
	assert_eq(list.size(), 3, "hit deve ter primário + 2 variantes (_2, _3)")

func test_round_robin_cycles_through_variants():
	var seen := {}
	for _i in 6:
		seen[_sfx._next_variant(_sfx.hit_sound)] = true
	assert_eq(seen.size(), 3, "round-robin deve tocar as 3 variantes ao longo do ciclo")

func test_play_routes_to_sfx_bus():
	_sfx.play(_sfx.hit_sound)
	var player: AudioStreamPlayer = null
	for child in _sfx.get_children():
		if child is AudioStreamPlayer:
			player = child
			break
	assert_not_null(player, "play() deve criar um AudioStreamPlayer")
	assert_eq(player.bus, SfxSystem.SFX_BUS)
