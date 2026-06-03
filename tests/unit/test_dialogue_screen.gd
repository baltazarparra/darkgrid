extends GutTest

const BOITATA_LINES: Array[Dictionary] = [
	{"speaker": "CAIPORA", "text": "Você nos traiu..."},
	{"speaker": "BOITATÁ", "text": "Vocês me abandonaram!"},
]

var _screen: DialogueScreen

func before_each() -> void:
	_screen = preload("res://scenes/ui/dialogue_screen.tscn").instantiate()
	add_child_autofree(_screen)

func test_start_shows_boss_name() -> void:
	_screen.start("BOITATÁ", BOITATA_LINES)
	assert_eq(_screen._boss_name_label.text, "BOITATÁ")

func test_start_shows_first_line() -> void:
	_screen.start("BOITATÁ", BOITATA_LINES)
	assert_eq(_screen._speaker_label.text, "CAIPORA")
	assert_eq(_screen._text_label.text, "Você nos traiu...")

func test_advance_shows_second_line() -> void:
	_screen.start("BOITATÁ", BOITATA_LINES)
	_screen.advance()
	assert_eq(_screen._speaker_label.text, "BOITATÁ")
	assert_eq(_screen._text_label.text, "Vocês me abandonaram!")

func test_advance_last_line_emits_dialogue_finished() -> void:
	watch_signals(SignalBus)
	_screen.start("BOITATÁ", BOITATA_LINES)
	_screen.advance()  # → linha 2
	_screen.advance()  # → fim
	assert_signal_emitted(SignalBus, "dialogue_finished")

func test_advance_ignored_when_not_ready() -> void:
	_screen.start("BOITATÁ", BOITATA_LINES)
	_screen._ready_for_input = false
	_screen.advance()
	assert_eq(_screen._speaker_label.text, "CAIPORA", "linha não deve avançar")
