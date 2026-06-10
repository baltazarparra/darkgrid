extends GutTest

const PerfHudScript := preload("res://scripts/ui/perf_hud.gd")

func test_percentile_empty_returns_zero() -> void:
	assert_eq(PerfHudScript.percentile(PackedFloat32Array(), 0.95), 0.0)

func test_percentile_nearest_rank() -> void:
	var samples := PackedFloat32Array([10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0])
	# nearest-rank: p95 de 10 amostras → rank ceil(0.95*10)=10 → 100.0
	assert_eq(PerfHudScript.percentile(samples, 0.95), 100.0)
	# p50 → rank ceil(0.5*10)=5 → 50.0
	assert_eq(PerfHudScript.percentile(samples, 0.5), 50.0)

func test_percentile_is_order_independent() -> void:
	var shuffled := PackedFloat32Array([90.0, 10.0, 50.0, 30.0, 70.0])
	assert_eq(PerfHudScript.percentile(shuffled, 0.5), 50.0)

func test_percentile_does_not_mutate_input() -> void:
	var samples := PackedFloat32Array([3.0, 1.0, 2.0])
	PerfHudScript.percentile(samples, 0.95)
	assert_eq(samples[0], 3.0)

func test_average() -> void:
	var samples := PackedFloat32Array([10.0, 20.0, 30.0])
	assert_almost_eq(PerfHudScript.average(samples), 20.0, 0.001)
	assert_eq(PerfHudScript.average(PackedFloat32Array()), 0.0)
