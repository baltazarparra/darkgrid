extends GutTest

# ArenaFraming: enquadramento da arena por orientação. Retrato aproxima os
# atores e estreita o retângulo de ação (combate grande no celular); bolhas
# de timing sempre nascem dentro do que a câmera vê.

const PHONE_PORTRAIT := Vector2(393, 852)
const PHONE_LANDSCAPE := Vector2(852, 393)
const TABLET_LANDSCAPE := Vector2(1180, 820)

func test_landscape_keeps_classic_stage() -> void:
	assert_eq(ArenaFraming.action_size(PHONE_LANDSCAPE), Vector2(560, 340), "palco clássico")
	assert_eq(ArenaFraming.caipora_pos(PHONE_LANDSCAPE), Vector2(160, 240), "caipora à esquerda")
	assert_eq(ArenaFraming.enemy_pos(PHONE_LANDSCAPE), Vector2(480, 240), "invasor à direita")

func test_portrait_pulls_actors_closer() -> void:
	var sep_portrait := ArenaFraming.enemy_pos(PHONE_PORTRAIT).x - ArenaFraming.caipora_pos(PHONE_PORTRAIT).x
	var sep_landscape := ArenaFraming.enemy_pos(PHONE_LANDSCAPE).x - ArenaFraming.caipora_pos(PHONE_LANDSCAPE).x
	assert_lt(sep_portrait, sep_landscape, "retrato aproxima os atores")
	var center := (ArenaFraming.enemy_pos(PHONE_PORTRAIT).x + ArenaFraming.caipora_pos(PHONE_PORTRAIT).x) * 0.5
	assert_eq(center, ArenaFraming.STAGE_CENTER.x, "dupla continua centrada no palco")
	assert_eq(ArenaFraming.caipora_pos(PHONE_PORTRAIT).y, ArenaFraming.GROUND_Y, "mesma linha de chão")

func test_portrait_action_rect_raises_zoom() -> void:
	# Mesma fórmula de fit do ArenaManager: contain do retângulo de ação.
	var action := ArenaFraming.action_size(PHONE_PORTRAIT)
	var raw := minf(PHONE_PORTRAIT.x / action.x, PHONE_PORTRAIT.y / action.y)
	var raw_palco_largo := minf(
		PHONE_PORTRAIT.x / ArenaFraming.LANDSCAPE_ACTION.x,
		PHONE_PORTRAIT.y / ArenaFraming.LANDSCAPE_ACTION.y)
	assert_gt(raw, raw_palco_largo * 1.3, "retrato amplia o combate em 30%+")
	# Num phone DPR 3 o snap de texel resolve para 1.0 (o palco largo caía em ~0.667).
	var z := PixelScale.snap_contain(clampf(raw * 0.92, 0.5, 2.0), 3.0, minf(raw, 2.0))
	assert_eq(z, 1.0, "texel inteiro com zoom cheio no phone retrato")

func test_bubble_rect_fits_view_in_both_orientations() -> void:
	for vp: Vector2 in [PHONE_PORTRAIT, PHONE_LANDSCAPE, TABLET_LANDSCAPE]:
		var action := ArenaFraming.action_size(vp)
		var z: float = clampf(minf(vp.x / action.x, vp.y / action.y) * 0.92, 0.5, 2.0)
		var rect := ArenaFraming.bubble_rect(ArenaFraming.STAGE_CENTER, vp, z)
		assert_gt(rect.size.x, 100.0, "área útil de bolhas em %s" % vp)
		assert_gt(rect.size.y, 100.0, "área útil de bolhas em %s" % vp)
		var visible := ArenaFraming.visible_rect(ArenaFraming.STAGE_CENTER, vp, z)
		assert_true(visible.encloses(rect), "bolhas dentro do que a câmera vê em %s" % vp)

func test_clamp_to_bubble_rect() -> void:
	var rect := Rect2(100, 100, 200, 100)
	assert_eq(ArenaFraming.clamp_to_bubble_rect(Vector2(50, 250), rect), Vector2(100, 200), "clampa pra borda")
	assert_eq(ArenaFraming.clamp_to_bubble_rect(Vector2(150, 150), rect), Vector2(150, 150), "interno fica")
	assert_eq(ArenaFraming.clamp_to_bubble_rect(Vector2(5, 5), Rect2(0, 0, -1, -1)), Vector2(5, 5),
		"rect degenerado não explode")
