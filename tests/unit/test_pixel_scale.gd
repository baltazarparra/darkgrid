extends GutTest

# snap_contain / snap_cover são funções puras — os casos cobrem os três perfis
# de plataforma (iPhone retrato, tablet, desktop) e viewports degeneradas.


func test_contain_snaps_to_nearest_integer_texel():
	# iPhone 17 retrato: s≈1.572; texel bruto 1.94 → 2 device-px exatos.
	var z: float = PixelScale.snap_contain(1.235, 1.572, 1.342)
	assert_almost_eq(z * 1.572, 2.0, 0.0001)


func test_contain_already_integer_is_unchanged():
	var z: float = PixelScale.snap_contain(2.0, 1.0, 2.2)
	assert_almost_eq(z, 2.0, 0.0001)


func test_contain_falls_to_floor_when_round_exceeds_hard_max():
	# round(1.6)=2 estouraria hard_max 1.7 → floor(1.6)=1.
	var z: float = PixelScale.snap_contain(1.6, 1.0, 1.7)
	assert_almost_eq(z, 1.0, 0.0001)


func test_contain_respects_tablet_cap_as_hard_max():
	# Tablet: zoom clampado em 2.0; s fracionário não pode snapar acima do teto.
	var z: float = PixelScale.snap_contain(2.0, 1.333, 2.0)
	assert_almost_eq(z, floorf(2.0 * 1.333) / 1.333, 0.0001)
	assert_true(z <= 2.0)


func test_contain_texel_floor_is_one():
	var z: float = PixelScale.snap_contain(0.7, 1.0, 2.0)
	assert_almost_eq(z, 1.0, 0.0001)


func test_contain_degenerate_keeps_raw_zoom():
	# Nem texel 1 cabe no hard_max → mantém fracionário (não corta o stage).
	var z: float = PixelScale.snap_contain(0.4, 1.0, 0.5)
	assert_almost_eq(z, 0.4, 0.0001)


func test_contain_invalid_inputs_keep_raw_zoom():
	assert_almost_eq(PixelScale.snap_contain(1.5, 0.0, 2.0), 1.5, 0.0001)
	assert_almost_eq(PixelScale.snap_contain(0.0, 1.0, 2.0), 0.0, 0.0001)


func test_cover_snaps_texel_up_never_below_raw():
	# Exploração desktop: cover 2.316 → texel 3 (nunca revela além dos limit_*).
	var z: float = PixelScale.snap_cover(2.316, 1.0)
	assert_almost_eq(z, 3.0, 0.0001)
	assert_true(z >= 2.316)


func test_cover_iphone_scale():
	# s≈1.572: texel bruto 3.64 → 4 device-px.
	var z: float = PixelScale.snap_cover(2.316, 1.572)
	assert_almost_eq(z * 1.572, 4.0, 0.0001)
	assert_true(z >= 2.316)


func test_cover_already_integer_is_unchanged():
	var z: float = PixelScale.snap_cover(3.0, 1.0)
	assert_almost_eq(z, 3.0, 0.0001)


func test_cover_degenerate_keeps_raw_zoom():
	# Texel bruto < 0.5: ceil inflaria o zoom 2x+ → mantém fracionário.
	var z: float = PixelScale.snap_cover(0.3, 1.0)
	assert_almost_eq(z, 0.3, 0.0001)


func test_cover_invalid_inputs_keep_raw_zoom():
	assert_almost_eq(PixelScale.snap_cover(2.0, 0.0), 2.0, 0.0001)
	assert_almost_eq(PixelScale.snap_cover(-1.0, 1.0), -1.0, 0.0001)
