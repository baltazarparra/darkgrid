class_name EndScreen
extends CanvasLayer

## Tela de fim de combate (WIN / GAME_OVER). Registra o resultado da run e volta
## ao Hub. Cada entrada é uma instância nova (change_scene_to_file), então o
## _ready dispara end_run exatamente uma vez por entrada.

@export var won: bool = false

func _ready() -> void:
	GameState.end_run(won)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		GameState.change_screen(SignalBus.Screen.HUB)
