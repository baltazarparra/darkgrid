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

# Janela para o 2º clique confirmar o reset antes de desarmar sozinho.
const RESET_CONFIRM_WINDOW: float = 3.0
const DANGER := Color(0.78, 0.1, 0.1, 1)

# ─── State ─────────────────────────────────────────
var _close_button: Button
var _first_slider: HSlider
var _last_focus: Control

var _touch_option: OptionButton
var _reset_button: Button
var _reset_armed: bool = false

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

	_add_touch_controls_row(vbox)
	_add_reset_row(vbox)

	_close_button = Button.new()
	_close_button.text = "Fechar"
	_close_button.add_theme_font_size_override("font_size", 16)
	_close_button.pressed.connect(close)
	vbox.add_child(_close_button)
	for control: Control in [_touch_option, _reset_button, _close_button]:
		_hook_hover(control)

## Tick de hover/foco central no AudioDirector (cooldown lá colapsa foco+mouse).
func _hook_hover(control: Control) -> void:
	control.focus_entered.connect(AudioDirector.play_ui_hover)
	control.mouse_entered.connect(AudioDirector.play_ui_hover)

func _add_touch_controls_row(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var label := Label.new()
	label.text = "Controles Touch"
	label.add_theme_color_override("font_color", TEXT)
	label.add_theme_font_size_override("font_size", 14)
	label.custom_minimum_size = Vector2(140, 0)
	row.add_child(label)

	var option := OptionButton.new()
	option.add_item("Auto", 0)
	option.add_item("Sempre", 1)
	option.add_item("Nunca", 2)
	option.custom_minimum_size = Vector2(220, 0)
	option.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var mode := MetaProgression.get_touch_controls_mode()
	match mode:
		"auto":   option.select(0)
		"always": option.select(1)
		"never":  option.select(2)

	option.item_selected.connect(_on_touch_mode_changed)
	row.add_child(option)
	parent.add_child(row)
	_touch_option = option

## Botão de perigo para apagar o progresso. Confirmação em dois passos no próprio botão
## (sem ConfirmationDialog, que tem foco problemático no mobile/touch).
func _add_reset_row(parent: VBoxContainer) -> void:
	_reset_button = Button.new()
	_reset_button.text = "Apagar progresso"
	_reset_button.add_theme_font_size_override("font_size", 14)
	_reset_button.add_theme_color_override("font_color", DANGER)
	_reset_button.pressed.connect(_on_reset_pressed)
	parent.add_child(_reset_button)

func _on_reset_pressed() -> void:
	if not _reset_armed:
		# 1º clique: arma e dá uma janela para confirmar antes de desarmar sozinho.
		_reset_armed = true
		_reset_button.text = "Confirmar? Apaga tudo."
		await get_tree().create_timer(RESET_CONFIRM_WINDOW).timeout
		if _reset_armed:
			_disarm_reset()
		return
	# 2º clique dentro da janela: apaga de fato.
	_reset_armed = false
	MetaProgression.reset_save()
	_reset_button.text = "Progresso apagado"
	if _touch_option != null:
		_touch_option.select(0)  # reflete touch_controls_mode = "auto"

func _disarm_reset() -> void:
	_reset_armed = false
	if is_instance_valid(_reset_button):
		_reset_button.text = "Apagar progresso"

func _on_touch_mode_changed(index: int) -> void:
	match index:
		0: MetaProgression.set_touch_controls_mode("auto")
		1: MetaProgression.set_touch_controls_mode("always")
		2: MetaProgression.set_touch_controls_mode("never")

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
	_hook_hover(slider)
	row.add_child(slider)

	if _first_slider == null:
		_first_slider = slider

	parent.add_child(row)

# ─── Public API ────────────────────────────────────
func open() -> void:
	# Recarrega os valores correntes (caso tenham mudado em outra tela).
	_last_focus = get_viewport().gui_get_focus_owner()
	_disarm_reset()  # nunca reabrir com o reset armado/concluído pendente
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
