class_name MainMenu
extends CanvasLayer

## Porta de entrada do jogo. Carrega o save no boot e roteia para o Hub.

@onready var _start_button: Button = $Center/VBox/StartButton
@onready var _vbox: VBoxContainer = $Center/VBox

var _options: OptionsPanel

func _ready() -> void:
	MetaProgression.load_progress()
	$Center/VBox/StartButton.pressed.connect(_on_start_pressed)
	$Center/VBox/QuitButton.pressed.connect(_on_quit_pressed)
	_add_options_ui()
	_start_button.grab_focus()

## Botão "Opções" (entre Iniciar e Sair) + overlay, montados em código.
func _add_options_ui() -> void:
	_options = OptionsPanel.new()
	add_child(_options)

	var options_button := Button.new()
	options_button.text = "Opções"
	options_button.add_theme_font_size_override("font_size", 18)
	options_button.pressed.connect(_on_options_pressed)
	_vbox.add_child(options_button)
	_vbox.move_child(options_button, $Center/VBox/QuitButton.get_index())

func _on_options_pressed() -> void:
	AudioDirector.unlock_audio()
	_options.open()

func _on_start_pressed() -> void:
	AudioDirector.unlock_audio()
	GameState.change_screen(SignalBus.Screen.HUB)

func _on_quit_pressed() -> void:
	get_tree().quit()
