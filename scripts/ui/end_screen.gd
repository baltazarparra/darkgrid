class_name EndScreen
extends CanvasLayer

## Tela de fim de combate (WIN / GAME_OVER). Registra o resultado da run e volta
## ao Hub. Cada entrada é uma instância nova (change_scene_to_file), então o
## _ready dispara end_run exatamente uma vez por entrada.

@export var won: bool = false

@onready var _hint: Label = $Center/VBox/Hint

func _ready() -> void:
	GameState.end_run(won)
	# No mobile não há tecla Space; orienta o toque e evita o dead-end.
	if DisplayServer.is_touchscreen_available():
		_hint.text = "Toque para voltar ao acampamento"

func _unhandled_input(event: InputEvent) -> void:
	# Space/Enter (desktop) OU qualquer toque/clique (mobile) volta ao acampamento.
	if event.is_action_pressed("ui_accept") \
			or (event is InputEventScreenTouch and event.pressed) \
			or (event is InputEventMouseButton and event.pressed):
		get_viewport().set_input_as_handled()
		GameState.change_screen(SignalBus.Screen.HUB)
