class_name EndScreen
extends CanvasLayer

## Tela placeholder de fim de combate (WIN / GAME_OVER). Resolve o beco sem
## saída da KI-004: o combate agora fecha o loop voltando à exploração.
## Será substituída por menus completos + hub na Fase 4.

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		GameState.change_screen(SignalBus.Screen.EXPLORATION)
