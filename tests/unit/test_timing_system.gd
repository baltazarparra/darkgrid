extends GutTest

var _timing: TimingSystem

func before_each():
    _timing = TimingSystem.new()
    add_child_autofree(_timing)

func test_perfect_timing_within_window():
    var result: Array = [TimingSystem.TimingResult.MISS]
    _timing.timing_result.connect(func(r): result[0] = r)
    _timing.open_window(1.0, 0.35, 0.65)
    _timing._window_progress = 0.5
    _timing._evaluate_timing()
    assert_eq(result[0], TimingSystem.TimingResult.PERFECT)

func test_miss_timing_outside_window():
    var result: Array = [TimingSystem.TimingResult.PERFECT]
    _timing.timing_result.connect(func(r): result[0] = r)
    _timing.open_window(1.0, 0.35, 0.65)
    _timing._window_progress = 0.1
    _timing._evaluate_timing()
    assert_eq(result[0], TimingSystem.TimingResult.MISS)

func test_miss_on_timeout():
    var result: Array = [TimingSystem.TimingResult.PERFECT]
    _timing.timing_result.connect(func(r): result[0] = r)
    _timing.open_window(0.1)
    await get_tree().create_timer(0.15).timeout
    assert_eq(result[0], TimingSystem.TimingResult.MISS)

func test_desktop_phase_timing_keeps_current_windows():
    assert_almost_eq(
        Constants.timing_window_for_phase(Constants.TIMING_WINDOW_ATTACK, 1, false),
        0.8,
        0.001
    )
    assert_almost_eq(
        Constants.timing_window_for_phase(Constants.TIMING_WINDOW_ATTACK, 4, false),
        0.5,
        0.001
    )

func test_touch_phase_timing_gets_point_two_second_bonus():
    assert_almost_eq(
        Constants.timing_window_for_phase(Constants.TIMING_WINDOW_ATTACK, 1, true),
        1.0,
        0.001
    )
    assert_almost_eq(
        Constants.timing_window_for_phase(Constants.TIMING_WINDOW_ATTACK, 4, true),
        0.7,
        0.001
    )
