class_name PortraitGuard
extends CanvasLayer

func _ready() -> void:
	layer = 128
	_build_overlay()
	get_viewport().size_changed.connect(_check)
	_check()

func _check() -> void:
	var vp := get_viewport().get_visible_rect().size
	visible = OS.has_feature("web") and vp.y > vp.x and vp.x < 640.0

func _build_overlay() -> void:
	var bg := ColorRect.new()
	bg.color = Constants.COLOR_NIGHT
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	var arrow := Label.new()
	arrow.text = ">> <<"
	arrow.add_theme_font_size_override("font_size", 24)
	arrow.add_theme_color_override("font_color", Constants.COLOR_AMBER)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(arrow)

	var msg := Label.new()
	msg.text = "Gire o dispositivo\npara jogar"
	msg.add_theme_font_size_override("font_size", 12)
	msg.add_theme_color_override("font_color", Constants.COLOR_TEXT)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(msg)
