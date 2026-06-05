class_name EndScreen
extends CanvasLayer

## Tela de fim de combate (WIN / GAME_OVER). Registra o resultado da run e encerra.
## Cada entrada é uma instância nova (change_scene_to_file), então o _ready dispara
## end_run exatamente uma vez por entrada.
##
## Roteamento de saída (a run JÁ acabou — end_run desativou run_active): a derrota volta
## ao MENU PRINCIPAL, não ao acampamento. O hub só entra ENTRE fases (advance_phase_via_hub);
## morrer não é avanço de fase. A vitória terminal mantém o acampamento.

@export var won: bool = false

@onready var _hint: Label = $Center/VBox/Hint

# Guard contra dupla ativação: com emulate_mouse_from_touch, um toque gera touch +
# mouse emulado no mesmo frame; só a primeira troca de tela deve valer.
var _handled: bool = false

func _ready() -> void:
	GameState.end_run(won)
	_hint.text = _hint_text()

## Tela-alvo ao dispensar (puro, sem efeitos colaterais — testável destacado da árvore).
## Derrota → MENU PRINCIPAL (a caçada acabou); vitória terminal → acampamento.
func _dismiss_target() -> SignalBus.Screen:
	return SignalBus.Screen.HUB if won else SignalBus.Screen.MAIN_MENU

## Dica de saída coerente com o destino e a plataforma (web/toque não têm barra de espaço).
func _hint_text() -> String:
	var destino := "acampamento" if won else "menu"
	if OS.has_feature("web") or DisplayServer.is_touchscreen_available():
		return "Toque para voltar ao %s" % destino
	return "Espaço para voltar ao %s" % destino

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
		GameState.change_screen(_dismiss_target())

# No mobile/tablet não há barra de espaço, então qualquer tecla, toque ou clique encerra.
func _is_dismiss_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed
	return false
