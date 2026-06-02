class_name Hub
extends CanvasLayer

## Santuário entre runs: recupera HP, exibe progresso, permite comprar upgrades
## permanentes (compra livre) e iniciar a próxima run.

@onready var _stats: Label = $Center/VBox/Stats
@onready var _upgrade_list: VBoxContainer = $Center/VBox/UpgradeList
@onready var _enter_button: Button = $Center/VBox/EnterButton

func _ready() -> void:
	GameState.heal_to_full()
	_refresh_stats()
	_build_upgrade_rows()
	_enter_button.pressed.connect(_on_enter_pressed)
	_enter_button.grab_focus()

func _refresh_stats() -> void:
	_stats.text = "Caçadas: %d    Vitórias: %d" % [MetaProgression.total_runs, MetaProgression.total_wins]

func _build_upgrade_rows() -> void:
	for key in MetaProgression.UPGRADE_DEFS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		row.alignment = BoxContainer.ALIGNMENT_CENTER

		var label := Label.new()
		label.add_theme_font_size_override("font_size", 14)
		label.custom_minimum_size = Vector2(260, 0)

		var button := Button.new()
		button.add_theme_font_size_override("font_size", 14)
		button.text = "Aprimorar"
		button.pressed.connect(_on_upgrade_pressed.bind(key, label, button))

		row.add_child(label)
		row.add_child(button)
		_upgrade_list.add_child(row)
		_update_row(key, label, button)

func _update_row(key: String, label: Label, button: Button) -> void:
	var def: Dictionary = MetaProgression.UPGRADE_DEFS[key]
	var level := MetaProgression.get_upgrade_level(key)
	var max_level := int(def["max_level"])
	label.text = "%s  Nv %d/%d" % [def["name"], level, max_level]
	button.disabled = level >= max_level

func _on_upgrade_pressed(key: String, label: Label, button: Button) -> void:
	if MetaProgression.purchase_upgrade(key):
		MetaProgression.save_progress()
		_update_row(key, label, button)

func _on_enter_pressed() -> void:
	GameState.start_run()
	GameState.change_screen(SignalBus.Screen.EXPLORATION)
