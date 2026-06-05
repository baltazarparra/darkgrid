class_name HubHud
extends CanvasLayer

# HUD do acampamento: contador de FRAGMENTOS + resumo dos bônus já fumados
# ("FÚRIA +X DANO · CURA +Y HP", de get_damage_bonus()/get_health_bonus()), instrução curta
# e acesso a OPÇÕES (herdado do antigo hub de cards: volumes, modo touch, reset). O HubManager
# chama refresh() a cada compra. Margens seguras espelham hud.gd (notch/safe-area).

const HINT_COLOR := Color(0.55, 0.55, 0.58, 1.0)  # texto apagado da instrução

var _frag_label: Label
var _bonus_label: Label
var _hint_label: Label
var _options_button: Button
var _margin: MarginContainer
var _options: OptionsPanel

func _ready() -> void:
	layer = 10
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_margin)

	# [ fragmentos/bônus à esquerda ] ··· [ Opções à direita ].
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.add_child(row)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(vbox)

	_frag_label = Label.new()
	_frag_label.add_theme_color_override("font_color", Constants.COLOR_AMBER)
	vbox.add_child(_frag_label)

	_bonus_label = Label.new()
	_bonus_label.add_theme_color_override("font_color", Constants.COLOR_TEXT)
	vbox.add_child(_bonus_label)

	_hint_label = Label.new()
	_hint_label.text = "piso na erva pra fumar • rastro leva à mata"
	_hint_label.add_theme_color_override("font_color", HINT_COLOR)
	vbox.add_child(_hint_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)

	_options = OptionsPanel.new()
	add_child(_options)
	_options_button = Button.new()
	_options_button.text = "Opções"
	_options_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_options_button.pressed.connect(_options.open)
	row.add_child(_options_button)

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
	_hint_label.add_theme_font_size_override("font_size", maxi(fs - 2, 8))
	_options_button.add_theme_font_size_override("font_size", fs)
