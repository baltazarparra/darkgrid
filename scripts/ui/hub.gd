class_name Hub
extends CanvasLayer

## Santuário entre runs: recupera HP, exibe fragmentos, permite comprar Força.

@onready var _stats: Label = $Center/VBox/Stats
@onready var _upgrade_list: VBoxContainer = $Center/VBox/UpgradeList
@onready var _enter_button: Button = $Center/VBox/EnterButton

var _options: OptionsPanel
var _forca_label: Label
var _forca_button: Button
var _saude_label: Label
var _saude_button: Button
var _forca2_label: Label
var _forca2_button: Button
var _saude2_label: Label
var _saude2_button: Button

func _ready() -> void:
	GameState.heal_to_full()
	_refresh_stats()
	_build_forca_row()
	_build_saude_row()
	if MetaProgression.phase_reached >= 2:
		_build_forca2_row()
		_build_saude2_row()
	_enter_button.pressed.connect(_on_enter_pressed)
	_add_options_ui()
	_enter_button.grab_focus()

## Botão "Opções" (abaixo de Entrar na Floresta) + overlay, montados em código.
func _add_options_ui() -> void:
	_options = OptionsPanel.new()
	add_child(_options)

	var options_button := Button.new()
	options_button.text = "Opções"
	options_button.add_theme_font_size_override("font_size", 16)
	options_button.pressed.connect(_on_options_pressed)
	$Center/VBox.add_child(options_button)

func _on_options_pressed() -> void:
	_options.open()

func _refresh_stats() -> void:
	_stats.text = "Caçadas: %d    Vitórias: %d" % [MetaProgression.total_runs, MetaProgression.total_wins]

func _build_forca_row() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	_forca_label = Label.new()
	_forca_label.add_theme_font_size_override("font_size", 14)
	_forca_label.custom_minimum_size = Vector2(260, 0)

	_forca_button = Button.new()
	_forca_button.add_theme_font_size_override("font_size", 14)
	_forca_button.text = "Comprar"
	_forca_button.pressed.connect(_on_forca_pressed)

	row.add_child(_forca_label)
	row.add_child(_forca_button)
	_upgrade_list.add_child(row)
	_refresh_forca_row()

func _refresh_forca_row() -> void:
	var frags := int(MetaProgression.fragments)
	var level := MetaProgression.get_upgrade_level("forca")
	var maxed := level >= 1
	if maxed:
		_forca_label.text = "Força  [APRIMORADO]  Fragmentos: %d" % frags
	else:
		_forca_label.text = "Força  Dano +1/hit  Fragmentos: %d / 4" % frags
	_forca_button.disabled = maxed or frags < 4

func _on_forca_pressed() -> void:
	if MetaProgression.purchase_upgrade("forca"):
		_refresh_forca_row()
		_refresh_saude_row()
		if _forca2_label != null:
			_refresh_forca2_row()

func _build_saude_row() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	_saude_label = Label.new()
	_saude_label.add_theme_font_size_override("font_size", 14)
	_saude_label.custom_minimum_size = Vector2(260, 0)

	_saude_button = Button.new()
	_saude_button.add_theme_font_size_override("font_size", 14)
	_saude_button.text = "Comprar"
	_saude_button.pressed.connect(_on_saude_pressed)

	row.add_child(_saude_label)
	row.add_child(_saude_button)
	_upgrade_list.add_child(row)
	_refresh_saude_row()

func _refresh_saude_row() -> void:
	var forca_comprada := MetaProgression.get_upgrade_level("forca") >= 1
	var frags := int(MetaProgression.fragments)
	var level := MetaProgression.get_upgrade_level("saude")
	var maxed := level >= 1
	_saude_label.get_parent().visible = forca_comprada
	if not forca_comprada:
		return
	if maxed:
		_saude_label.text = "Saúde  [APRIMORADO]  Fragmentos: %d" % frags
	else:
		_saude_label.text = "Saúde  +2 HP (permanente)  Fragmentos: %d / 6" % frags
	_saude_button.disabled = maxed or frags < 6

func _on_saude_pressed() -> void:
	if MetaProgression.purchase_upgrade("saude"):
		_refresh_saude_row()

func _build_forca2_row() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	_forca2_label = Label.new()
	_forca2_label.add_theme_font_size_override("font_size", 14)
	_forca2_label.custom_minimum_size = Vector2(260, 0)

	_forca2_button = Button.new()
	_forca2_button.add_theme_font_size_override("font_size", 14)
	_forca2_button.text = "Comprar"
	_forca2_button.pressed.connect(_on_forca2_pressed)

	row.add_child(_forca2_label)
	row.add_child(_forca2_button)
	_upgrade_list.add_child(row)
	_refresh_forca2_row()

func _refresh_forca2_row() -> void:
	var forca_comprada := MetaProgression.get_upgrade_level("forca") >= 1
	var frags := int(MetaProgression.fragments)
	var level := MetaProgression.get_upgrade_level("forca_2")
	var maxed := level >= 1
	_forca2_label.get_parent().visible = forca_comprada
	if not forca_comprada:
		return
	if maxed:
		_forca2_label.text = "Fúria da Floresta  [APRIMORADO]  Fragmentos: %d" % frags
	else:
		_forca2_label.text = "Fúria da Floresta  Dano +1/hit (total 3)  Fragmentos: %d / 6" % frags
	_forca2_button.disabled = maxed or frags < 6 or not forca_comprada

func _on_forca2_pressed() -> void:
	if MetaProgression.purchase_upgrade("forca_2"):
		_refresh_forca2_row()

func _build_saude2_row() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	_saude2_label = Label.new()
	_saude2_label.add_theme_font_size_override("font_size", 14)
	_saude2_label.custom_minimum_size = Vector2(260, 0)

	_saude2_button = Button.new()
	_saude2_button.add_theme_font_size_override("font_size", 14)
	_saude2_button.text = "Comprar"
	_saude2_button.pressed.connect(_on_saude2_pressed)

	row.add_child(_saude2_label)
	row.add_child(_saude2_button)
	_upgrade_list.add_child(row)
	_refresh_saude2_row()

func _refresh_saude2_row() -> void:
	var frags := int(MetaProgression.fragments)
	var level := MetaProgression.get_upgrade_level("saude_2")
	var maxed := level >= 1
	if maxed:
		_saude2_label.text = "Pele de Árvore  [APRIMORADO]  Fragmentos: %d" % frags
	else:
		_saude2_label.text = "Pele de Árvore  +2 HP  Fragmentos: %d / 9" % frags
	_saude2_button.disabled = maxed or frags < 9

func _on_saude2_pressed() -> void:
	if MetaProgression.purchase_upgrade("saude_2"):
		_refresh_saude2_row()

func _on_enter_pressed() -> void:
	GameState.start_run()
	GameState.change_screen(SignalBus.Screen.EXPLORATION)
