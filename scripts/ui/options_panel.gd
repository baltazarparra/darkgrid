class_name OptionsPanel
extends CanvasLayer

## Overlay de Opções reutilizável, construído em código (espelha o padrão do
## Atmosphere). Instanciado por main_menu e hub; mostra/esconde sobre a tela atual
## sem tocar na máquina de telas. Sliders ligados ao AudioDirector (que persiste em
## user://settings.cfg).

# ─── Constants ─────────────────────────────────────
const OVERLAY_LAYER: int = 60
const PANEL_BG := Color(0.051, 0.067, 0.09, 0.96)
const DIM_BG := Color(0, 0, 0, 0.6)
const ACCENT := Color(0.545, 0, 0, 1)
const TEXT := Color(0.788, 0.82, 0.851, 1)

# Linhas: (rótulo, nome do bus). Literais para manter const em tempo de parse — os
# nomes batem com os buses de default_bus_layout.tres / AudioDirector.
const ROWS: Array = [
	["Geral", "Master"],
	["Efeitos", "SFX"],
	["Música", "Music"],
	["Ambiência", "Ambience"],
]

# ─── State ─────────────────────────────────────────
var _close_button: Button
var _first_slider: HSlider
var _last_focus: Control

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	layer = OVERLAY_LAYER
	visible = false
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = DIM_BG
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP  # bloqueia cliques na tela de baixo
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = ACCENT
	style.set_border_width_all(2)  # bordas duras, sem cantos arredondados
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "OPÇÕES"
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	for row in ROWS:
		_add_slider_row(vbox, row[0], row[1])

	_close_button = Button.new()
	_close_button.text = "Fechar"
	_close_button.add_theme_font_size_override("font_size", 16)
	_close_button.pressed.connect(close)
	vbox.add_child(_close_button)

func _add_slider_row(parent: VBoxContainer, label_text: String, bus_name: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", TEXT)
	label.add_theme_font_size_override("font_size", 14)
	label.custom_minimum_size = Vector2(140, 0)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = AudioDirector.get_bus_volume(bus_name)
	slider.custom_minimum_size = Vector2(220, 0)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(_on_slider_changed.bind(bus_name))
	row.add_child(slider)

	if _first_slider == null:
		_first_slider = slider

	parent.add_child(row)

# ─── Public API ────────────────────────────────────
func open() -> void:
	# Recarrega os valores correntes (caso tenham mudado em outra tela).
	_last_focus = get_viewport().gui_get_focus_owner()
	visible = true
	if _first_slider != null:
		_first_slider.grab_focus()

func close() -> void:
	visible = false
	if is_instance_valid(_last_focus):
		_last_focus.grab_focus()

# ─── Private ───────────────────────────────────────
func _on_slider_changed(value: float, bus_name: String) -> void:
	AudioDirector.set_bus_volume(bus_name, value)
