class_name TimingCue
extends CanvasLayer

const BAR_WIDTH := 200.0
const BAR_HEIGHT := 20.0

var _bg: ColorRect
var _bar: ColorRect
var _tween: Tween

func _ready() -> void:
	visible = false
	
	var container := CenterContainer.new()
	container.set_anchors_preset(Control.PRESET_CENTER)
	add_child(container)
	
	_bg = ColorRect.new()
	_bg.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_bg.color = Constants.COLOR_EARTH
	container.add_child(_bg)
	
	_bar = ColorRect.new()
	_bar.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_bar.color = Constants.COLOR_AMBER
	_bar.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_bg.add_child(_bar)

func show_cue(duration: float) -> void:
	visible = true
	_bar.size.x = BAR_WIDTH
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_bar, "size:x", 0.0, duration)
	_tween.tween_callback(hide_cue)

func hide_cue() -> void:
	visible = false
	if _tween != null and _tween.is_valid():
		_tween.kill()

func get_progress() -> float:
	if not visible or _bg == null:
		return 0.0
	return 1.0 - (_bar.size.x / BAR_WIDTH)
