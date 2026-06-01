class_name TimingSystem
extends Node

enum TimingResult { PERFECT, MISS }

# ─── Signals ───────────────────────────────────────
signal timing_result(result: TimingResult)
signal timing_first_hit

# ─── State ─────────────────────────────────────────
var _is_window_open: bool = false
var _window_progress: float = 0.0
var _window_duration: float = 1.5
var _perfect_start: float = 0.35
var _perfect_end: float = 0.65
var _double_mode: bool = false
var _first_press_elapsed: float = -1.0

# ─── Public API ────────────────────────────────────
func open_window(duration: float = 1.5, perfect_start: float = 0.35, perfect_end: float = 0.65, double: bool = false) -> void:
	_is_window_open = true
	_window_duration = duration
	_perfect_start = perfect_start
	_perfect_end = perfect_end
	_double_mode = double
	_first_press_elapsed = -1.0
	_window_progress = 0.0

func close_window() -> void:
	_is_window_open = false

# ─── Lifecycle ─────────────────────────────────────
func _process(delta: float) -> void:
	if not _is_window_open:
		return
	_window_progress += delta / _window_duration
	if _window_progress >= 1.0:
		_is_window_open = false
		timing_result.emit(TimingResult.MISS)

func _input(event: InputEvent) -> void:
	if not _is_window_open:
		return
	if event.is_action_pressed("ui_accept"):
		_evaluate_timing()

# ─── Private helpers ───────────────────────────────
func _in_perfect_zone() -> bool:
	return _window_progress >= _perfect_start and _window_progress <= _perfect_end

func _evaluate_timing() -> void:
	if not _double_mode:
		_is_window_open = false
		if _in_perfect_zone():
			timing_result.emit(TimingResult.PERFECT)
		else:
			timing_result.emit(TimingResult.MISS)
		return

	var elapsed: float = _window_progress * _window_duration

	if _first_press_elapsed < 0.0:
		if _in_perfect_zone():
			_first_press_elapsed = elapsed
			timing_first_hit.emit()
		else:
			_is_window_open = false
			timing_result.emit(TimingResult.MISS)
	else:
		var interval: float = elapsed - _first_press_elapsed
		_is_window_open = false
		if _in_perfect_zone() and interval >= Constants.TIMING_DOUBLE_MIN_INTERVAL:
			timing_result.emit(TimingResult.PERFECT)
		else:
			timing_result.emit(TimingResult.MISS)
