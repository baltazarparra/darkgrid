class_name DialogueScreen
extends CanvasLayer

@onready var _boss_name_label: Label = $BossName
@onready var _speaker_label: Label = $SpeechBox/VBox/SpeakerLabel
@onready var _text_label: Label = $SpeechBox/VBox/TextLabel
@onready var _indicator: Label = $SpeechBox/VBox/Indicator

var _lines: Array[Dictionary] = []
var _current_index: int = 0
var _ready_for_input: bool = false

# ─── Public API ────────────────────────────────────

func start(boss_name: String, lines: Array[Dictionary]) -> void:
	_lines = lines
	_current_index = 0
	_boss_name_label.text = boss_name
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

func _unhandled_input(event: InputEvent) -> void:
	var triggered: bool = event.is_action_pressed("ui_accept") \
		or (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed)
	if triggered:
		get_viewport().set_input_as_handled()
		advance()

# ─── Private helpers ───────────────────────────────

func _show_line(idx: int) -> void:
	var line: Dictionary = _lines[idx]
	_speaker_label.text = line.get("speaker", "")
	_text_label.text = line.get("text", "")
	_indicator.visible = true
	_ready_for_input = true
