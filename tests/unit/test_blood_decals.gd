extends GutTest

var _decals: BloodDecals

func before_each():
	_decals = BloodDecals.new()
	add_child_autofree(_decals)

func test_splat_accumulates_multiple_blobs():
	_decals.add_splat(Vector2(100, 100), 1.0)
	# intensity 1.0 → 4 manchas por golpe
	assert_eq(_decals._splats.size(), 4)

func test_death_spills_more_than_hit():
	_decals.add_splat(Vector2.ZERO, 1.0)
	var hit_count: int = _decals._splats.size()
	_decals._splats.clear()
	_decals.add_splat(Vector2.ZERO, 2.6)
	assert_gt(_decals._splats.size(), hit_count)

func test_splats_capped_fifo():
	for i in 80:
		_decals.add_splat(Vector2(i, 0), 2.6)
	assert_lte(_decals._splats.size(), BloodDecals.MAX_SPLATS)

func test_splat_projects_to_ground():
	_decals.add_splat(Vector2(100, 100), 0.0)
	for splat in _decals._splats:
		var pos: Vector2 = splat["pos"]
		# intensity 0 → sem espalhamento: cai exatamente no chão sob o ator
		assert_almost_eq(pos.y, 100.0 + BloodDecals.GROUND_OFFSET, 0.01)
