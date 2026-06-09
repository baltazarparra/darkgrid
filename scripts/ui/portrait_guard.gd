extends CanvasLayer
# Autoload registrado como PortraitGuard em project.godot.
# Sem class_name: conflita com o nome do autoload em Godot 4.

func _ready() -> void:
	layer = 128
	_build_overlay()
	get_viewport().size_changed.connect(_check)
	_check()

func _check() -> void:
	# Retrato é a orientação primária: o overlay pede para GIRAR quando um telefone está em
	# paisagem. Só telefones (lado curto < limite) — tablet/desktop em paisagem jogam normal.
	var vp := get_viewport().get_visible_rect().size
	visible = OS.has_feature("web") and not Constants.is_portrait(vp) and minf(vp.x, vp.y) < Constants.PHONE_SHORT_SIDE_MAX

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
