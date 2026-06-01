class_name MainMenu
extends CanvasLayer

## Porta de entrada do jogo. Carrega o save no boot e roteia para o Hub.

@onready var _start_button: Button = $Center/VBox/StartButton

func _ready() -> void:
	MetaProgression.load_progress()
	$Center/VBox/StartButton.pressed.connect(_on_start_pressed)
	$Center/VBox/QuitButton.pressed.connect(_on_quit_pressed)
	_start_button.grab_focus()

func _on_start_pressed() -> void:
	GameState.change_screen(SignalBus.Screen.HUB)

func _on_quit_pressed() -> void:
	get_tree().quit()
