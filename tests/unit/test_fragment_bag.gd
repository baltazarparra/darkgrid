extends GutTest

# Souls-like / corpse run: ao morrer a Caipora derruba TODOS os fragmentos numa bolsa, no
# lugar da morte (fase + tile). Reaver pisando nela; morrer antes de chegar perde tudo.
# Cobre o estado persistente em MetaProgression (drop/recover/overwrite + save round-trip).

var _original_save_path: String

func before_each():
	_original_save_path = MetaProgression.SAVE_PATH
	MetaProgression.SAVE_PATH = "user://test_savegame.json"
	_reset_bag_state()

func after_each():
	if FileAccess.file_exists(MetaProgression.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(MetaProgression.SAVE_PATH))
	MetaProgression.SAVE_PATH = _original_save_path
	_reset_bag_state()

func _reset_bag_state():
	MetaProgression.fragments = 0.0
	MetaProgression.frag_bag_active = false
	MetaProgression.frag_bag_phase = 0
	MetaProgression.frag_bag_pos = Vector2i.ZERO
	MetaProgression.frag_bag_amount = 0.0

func test_drop_moves_all_fragments_into_bag():
	MetaProgression.fragments = 12.0
	MetaProgression.drop_fragment_bag(2, Vector2i(5, 7))
	assert_eq(MetaProgression.fragments, 0.0, "saldo zera ao derrubar a bolsa")
	assert_true(MetaProgression.frag_bag_active)
	assert_eq(MetaProgression.frag_bag_amount, 12.0)
	assert_eq(MetaProgression.frag_bag_phase, 2)
	assert_eq(MetaProgression.frag_bag_pos, Vector2i(5, 7))

func test_has_bag_only_in_drop_phase():
	MetaProgression.fragments = 8.0
	MetaProgression.drop_fragment_bag(3, Vector2i(1, 1))
	assert_true(MetaProgression.has_bag_in_phase(3), "bolsa visível na fase da morte")
	assert_false(MetaProgression.has_bag_in_phase(1), "não aparece em outra fase")
	assert_false(MetaProgression.has_bag_in_phase(2))

func test_recover_restores_fragments_and_clears_bag():
	MetaProgression.fragments = 20.0
	MetaProgression.drop_fragment_bag(1, Vector2i(4, 4))
	var got := MetaProgression.recover_fragment_bag()
	assert_eq(got, 20.0, "recupera o valor derrubado")
	assert_eq(MetaProgression.fragments, 20.0, "saldo volta ao que era")
	assert_false(MetaProgression.frag_bag_active, "bolsa some após recuperar")
	assert_false(MetaProgression.has_bag_in_phase(1))

func test_recover_no_bag_is_noop():
	MetaProgression.fragments = 5.0
	var got := MetaProgression.recover_fragment_bag()
	assert_eq(got, 0.0)
	assert_eq(MetaProgression.fragments, 5.0)

func test_drop_with_zero_fragments_marks_no_bag():
	MetaProgression.fragments = 0.0
	MetaProgression.drop_fragment_bag(1, Vector2i(2, 2))
	assert_false(MetaProgression.frag_bag_active, "morrer sem fragmento não deixa bolsa")

func test_dying_again_overwrites_and_loses_old_bag():
	# Derruba 30 na fase 2 e morre de novo (já com 0) na fase 1 antes de recuperar:
	# a bolsa antiga (e seus 30) some — segue com zero.
	MetaProgression.fragments = 30.0
	MetaProgression.drop_fragment_bag(2, Vector2i(9, 9))
	MetaProgression.fragments = 0.0
	MetaProgression.drop_fragment_bag(1, Vector2i(3, 3))
	assert_false(MetaProgression.has_bag_in_phase(2), "bolsa antiga perdida")
	assert_false(MetaProgression.frag_bag_active, "nova morte sem frags não deixa bolsa")

func test_dying_again_with_new_frags_replaces_bag():
	MetaProgression.fragments = 30.0
	MetaProgression.drop_fragment_bag(2, Vector2i(9, 9))
	MetaProgression.fragments = 4.0
	MetaProgression.drop_fragment_bag(1, Vector2i(3, 3))
	assert_false(MetaProgression.has_bag_in_phase(2), "bolsa antiga (30) perdida")
	assert_true(MetaProgression.has_bag_in_phase(1), "nova bolsa na nova morte")
	assert_eq(MetaProgression.frag_bag_amount, 4.0)

func test_bag_survives_save_round_trip():
	MetaProgression.fragments = 15.0
	MetaProgression.drop_fragment_bag(4, Vector2i(6, 11))
	MetaProgression.save_progress()
	_reset_bag_state()
	MetaProgression.load_progress()
	assert_true(MetaProgression.frag_bag_active)
	assert_eq(MetaProgression.frag_bag_amount, 15.0)
	assert_eq(MetaProgression.frag_bag_phase, 4)
	assert_eq(MetaProgression.frag_bag_pos, Vector2i(6, 11))

func test_reset_save_clears_bag():
	MetaProgression.fragments = 10.0
	MetaProgression.drop_fragment_bag(2, Vector2i(1, 2))
	MetaProgression.reset_save()
	assert_false(MetaProgression.frag_bag_active)
	assert_eq(MetaProgression.frag_bag_amount, 0.0)
