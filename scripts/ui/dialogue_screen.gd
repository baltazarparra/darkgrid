class_name DialogueScreen
extends CanvasLayer

@onready var _boss_name_label: Label = $BossName
@onready var _left_box: ColorRect  = $LeftBox
@onready var _right_box: ColorRect = $RightBox
@onready var _left_speaker_label:  Label = $LeftBox/VBox/SpeakerLabel
@onready var _left_text_label:     Label = $LeftBox/VBox/TextLabel
@onready var _left_indicator:      Label = $LeftBox/VBox/Indicator
@onready var _right_speaker_label: Label = $RightBox/VBox/SpeakerLabel
@onready var _right_text_label:    Label = $RightBox/VBox/TextLabel
@onready var _right_indicator:     Label = $RightBox/VBox/Indicator

var _lines: Array[Dictionary] = []
var _current_index: int = 0
var _ready_for_input: bool = false
var _left_speaker_name: String = ""
var _last_input_frame: int = -1

# ─── Public API ────────────────────────────────────

func start(boss_name: String, lines: Array[Dictionary],
		left_speaker: String = "CAIPORA",
		left_color: Color = Color.WHITE,
		right_color: Color = Color.WHITE) -> void:
	_lines = lines
	_current_index = 0
	_left_speaker_name = left_speaker
	_boss_name_label.text = boss_name
	_left_speaker_label.add_theme_color_override("font_color", left_color)
	_right_speaker_label.add_theme_color_override("font_color", right_color)
	_show_line(0)

## Avança para a próxima fala. Chamado via input ou diretamente em testes.
func advance() -> void:
	if not _ready_for_input:
		return
	_ready_for_input = false
	_current_index += 1
	if _current_index < _lines.size():
		_show_line(_current_index)
	else:
		SignalBus.dialogue_finished.emit()
		queue_free()

# ─── Input ─────────────────────────────────────────

# Usa _input (não _unhandled_input): o overlay/caixas de diálogo são ColorRects com
# mouse_filter=STOP por padrão, que engolem o toque na fase de GUI antes de chegar ao
# input "não tratado". No desktop a barra de espaço (tecla) escapava disso, mas no mobile
# não há teclado e o toque morria no overlay — travando o diálogo do boss Boitatá.
# _input roda antes da GUI, então o toque é capturado e a fala avança.
func _input(event: InputEvent) -> void:
	if not _is_advance_event(event):
		return
	# Com emulate_mouse_from_touch ligado, um único toque gera DOIS eventos no mesmo
	# frame (touch + mouse emulado). A guarda de frame descarta o segundo, avançando
	# exatamente uma fala por toque.
	var frame := Engine.get_process_frames()
	if frame == _last_input_frame:
		return
	_last_input_frame = frame
	get_viewport().set_input_as_handled()
	advance()

# ─── Private helpers ───────────────────────────────

# No mobile/tablet não há barra de espaço, então qualquer tecla, toque ou clique avança a
# fala. No desktop isso mantém o Space funcionando (é uma tecla) e ainda aceita Enter, etc.
func _is_advance_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed
	return false

func _show_line(idx: int) -> void:
	var line: Dictionary = _lines[idx]
	var speaker: String = line.get("speaker", "")
	var is_left: bool = speaker == _left_speaker_name

	_left_box.visible = is_left
	_right_box.visible = not is_left

	if is_left:
		_left_speaker_label.text = speaker
		_left_text_label.text = line.get("text", "")
		_left_indicator.visible = true
	else:
		_right_speaker_label.text = speaker
		_right_text_label.text = line.get("text", "")
		_right_indicator.visible = true

	_ready_for_input = true
