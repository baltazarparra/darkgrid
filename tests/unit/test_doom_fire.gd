extends GutTest

func _make_fire() -> DoomFire:
	var fire := DoomFire.new()
	add_child_autofree(fire)
	return fire

func test_palette_bake_roundtrip() -> void:
	var packed := DoomFire._bake_palette()
	assert_eq(packed.size(), DoomFire.PALETTE.size())
	for i in DoomFire.PALETTE.size():
		var c: Color = DoomFire.PALETTE[i]
		var v: int = packed[i]
		assert_eq(v & 0xFF, c.r8, "r do índice %d" % i)
		assert_eq((v >> 8) & 0xFF, c.g8, "g do índice %d" % i)
		assert_eq((v >> 16) & 0xFF, c.b8, "b do índice %d" % i)
		assert_eq((v >> 24) & 0xFF, c.a8, "a do índice %d" % i)

func test_seed_row_uses_top_palette_index() -> void:
	var fire := _make_fire()
	var seed_row: int = (DoomFire.ROWS - 1) * fire._cols
	for col in fire._cols:
		assert_eq(fire._grid[seed_row + col], DoomFire.PALETTE.size() - 1)

func test_fire_propagates_upward() -> void:
	var fire := _make_fire()
	fire._update_fire()
	# decay máximo por passo é DECAY_RANGE-1: a linha acima da fonte nunca apaga
	var row_base: int = (DoomFire.ROWS - 2) * fire._cols
	var max_val: int = 0
	for col in fire._cols:
		max_val = maxi(max_val, fire._grid[row_base + col])
	assert_gte(max_val, DoomFire.PALETTE.size() - DoomFire.DECAY_RANGE)

func test_blit_writes_full_rgba_buffer() -> void:
	var fire := _make_fire()
	fire._update_fire()
	fire._blit_image()
	assert_eq(fire._image.get_data().size(), fire._cols * DoomFire.ROWS * 4)

func test_blit_matches_palette_colors() -> void:
	var fire := _make_fire()
	fire._update_fire()
	fire._blit_image()
	var row: int = DoomFire.ROWS - 2
	for col in mini(fire._cols, 8):
		var idx: int = fire._grid[row * fire._cols + col]
		var px: Color = fire._image.get_pixel(col, row)
		var expected: Color = DoomFire.PALETTE[idx]
		assert_almost_eq(px.r, expected.r, 0.01, "col %d" % col)
		assert_almost_eq(px.g, expected.g, 0.01, "col %d" % col)
		assert_almost_eq(px.b, expected.b, 0.01, "col %d" % col)
		assert_almost_eq(px.a, expected.a, 0.01, "col %d" % col)
