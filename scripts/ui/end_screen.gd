class_name EndScreen
extends CanvasLayer

## Tela de fim de combate (WIN / GAME_OVER). Registra o resultado da run e volta
## ao Hub. Cada entrada é uma instância nova (change_scene_to_file), então o
## _ready dispara end_run exatamente uma vez por entrada.

@export var won: bool = false

@onready var _hint: Label = $Center/VBox/Hint

# Guard contra dupla ativação: com emulate_mouse_from_touch, um toque gera touch +
# mouse emulado no mesmo frame; só a primeira troca de tela deve valer.
var _handled: bool = false

func _ready() -> void:
	GameState.end_run(won)
	# No mobile não há tecla Space; orienta o toque e evita o dead-end.
	if OS.has_feature("web") or DisplayServer.is_touchscreen_available():
		_hint.text = "Toque para voltar ao acampamento"

# Usa _input (não _unhandled_input): o Background/CenterContainer cobrem a tela inteira com
# mouse_filter=STOP por padrão, engolindo o toque na fase de GUI. No mobile, sem barra de
# espaço, isso transformava a tela num dead-end. _input roda antes da GUI e captura o toque.
func _input(event: InputEvent) -> void:
	# Qualquer tecla (desktop) OU qualquer toque/clique (mobile) volta ao acampamento.
	if _handled:
		return
	if _is_dismiss_event(event):
		_handled = true
		get_viewport().set_input_as_handled()
		GameState.change_screen(SignalBus.Screen.HUB)

# No mobile/tablet não há barra de espaço, então qualquer tecla, toque ou clique encerra.
func _is_dismiss_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed
	return false
