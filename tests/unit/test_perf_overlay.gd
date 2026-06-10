extends GutTest

const PerfOverlayScript := preload("res://scripts/ui/perf_overlay.gd")

func test_percentile_empty_returns_zero():
	assert_eq(PerfOverlayScript.percentile(PackedFloat32Array(), 0.95), 0.0)

func test_percentile_nearest_rank():
	var samples := PackedFloat32Array([10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0])
	# nearest-rank: p95 de 10 amostras → rank ceil(0.95*10)=10 → 100.0
	assert_eq(PerfOverlayScript.percentile(samples, 0.95), 100.0)
	# p50 → rank ceil(0.5*10)=5 → 50.0
	assert_eq(PerfOverlayScript.percentile(samples, 0.5), 50.0)

func test_percentile_is_order_independent():
	var shuffled := PackedFloat32Array([90.0, 10.0, 50.0, 30.0, 70.0])
	assert_eq(PerfOverlayScript.percentile(shuffled, 0.5), 50.0)

func test_percentile_does_not_mutate_input():
	var samples := PackedFloat32Array([3.0, 1.0, 2.0])
	PerfOverlayScript.percentile(samples, 0.95)
	assert_eq(samples[0], 3.0)

func test_average():
	var samples := PackedFloat32Array([10.0, 20.0, 30.0])
	assert_almost_eq(PerfOverlayScript.average(samples), 20.0, 0.001)
	assert_eq(PerfOverlayScript.average(PackedFloat32Array()), 0.0)

func test_overlay_starts_disabled_and_costless():
	var overlay := PerfOverlayScript.new()
	add_child_autofree(overlay)
	assert_false(overlay.is_processing(), "overlay deve nascer com _process desligado")
	assert_null(overlay._label, "nada deve ser construído enquanto desligado")
