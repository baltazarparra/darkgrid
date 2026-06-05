class_name HubHud
extends CanvasLayer

# HUD do acampamento: contador de FRAGMENTOS + resumo dos bônus já fumados
# ("FÚRIA +X DANO · CURA +Y HP", de get_damage_bonus()/get_health_bonus()). O HubManager
# chama refresh() a cada compra. Margens seguras espelham hud.gd (notch/safe-area).

var _frag_label: Label
var _bonus_label: Label
var _margin: MarginContainer

func _ready() -> void:
	layer = 10
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.add_child(vbox)

	_frag_label = Label.new()
	_frag_label.add_theme_color_override("font_color", Constants.COLOR_AMBER)
	vbox.add_child(_frag_label)

	_bonus_label = Label.new()
	_bonus_label.add_theme_color_override("font_color", Constants.COLOR_TEXT)
	vbox.add_child(_bonus_label)

	_apply_safe_margins()
	get_viewport().size_changed.connect(_apply_safe_margins)
	refresh()

## Reescreve fragmentos e o resumo de bônus a partir do MetaProgression (fonte de verdade).
func refresh() -> void:
	_frag_label.text = "Fragmentos: %d" % int(MetaProgression.fragments)
	_bonus_label.text = "Fúria +%d dano   Cura +%d HP" % [
		MetaProgression.get_damage_bonus(), MetaProgression.get_health_bonus()
	]

func _apply_safe_margins() -> void:
	var vp := get_viewport().get_visible_rect().size
	var top: int = int(clampf(minf(vp.x, vp.y) * 0.05, 28.0, 64.0))
	var side: int = int(clampf(minf(vp.x, vp.y) * 0.055, 40.0, 80.0))
	var fs: int = int(clampf(minf(vp.x, vp.y) * 0.024, 10.0, 18.0))
	_margin.add_theme_constant_override("margin_top", top)
	_margin.add_theme_constant_override("margin_left", side)
	_margin.add_theme_constant_override("margin_right", side)
	_frag_label.add_theme_font_size_override("font_size", fs)
	_bonus_label.add_theme_font_size_override("font_size", fs)
