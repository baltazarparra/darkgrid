class_name Hub
extends CanvasLayer

## Santuário entre runs: recupera HP, exibe fragmentos, permite comprar Força.

@onready var _stats: Label = $Center/VBox/Stats
@onready var _upgrade_list: VBoxContainer = $Center/VBox/UpgradeList
@onready var _enter_button: Button = $Center/VBox/EnterButton

var _forca_label: Label
var _forca_button: Button

func _ready() -> void:
	GameState.heal_to_full()
	_refresh_stats()
	_build_forca_row()
	_enter_button.pressed.connect(_on_enter_pressed)
	_enter_button.grab_focus()

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
	var frags := MetaProgression.fragments
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

func _on_enter_pressed() -> void:
	GameState.start_run()
	GameState.change_screen(SignalBus.Screen.EXPLORATION)
