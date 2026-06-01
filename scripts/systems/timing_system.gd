class_name TimingSystem
extends Node

enum TimingResult { PERFECT, MISS }

signal timing_result(result: TimingResult)

var _is_window_open: bool = false
var _window_progress: float = 0.0
var _window_duration: float = 1.5
var _perfect_start: float = 0.35
var _perfect_end: float = 0.65

func open_window(duration: float = 1.5, perfect_start: float = 0.35, perfect_end: float = 0.65) -> void:
    _is_window_open = true
    _window_duration = duration
    _perfect_start = perfect_start
    _perfect_end = perfect_end
    _window_progress = 0.0

func close_window() -> void:
    _is_window_open = false

func _process(delta: float) -> void:
    if _is_window_open:
        _window_progress += delta / _window_duration
        if _window_progress >= 1.0:
            _is_window_open = false
            timing_result.emit(TimingResult.MISS)

func _input(event: InputEvent) -> void:
    if not _is_window_open:
        return
    if event.is_action_pressed("ui_accept"):
        _evaluate_timing()

func _evaluate_timing() -> void:
    _is_window_open = false
    if _window_progress >= _perfect_start and _window_progress <= _perfect_end:
        timing_result.emit(TimingResult.PERFECT)
    else:
        timing_result.emit(TimingResult.MISS)
