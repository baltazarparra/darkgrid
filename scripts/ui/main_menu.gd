class_name MainMenu
extends CanvasLayer

## Porta de entrada do jogo. Carrega o save no boot e roteia para o Hub.
## A abertura "Horizonte Infernal" (fogo, treelines, brasas, Caipora andando) é
## montada na cena; aqui cuidamos do fade-in/out e da vida do título.

# ─── Constants ─────────────────────────────────────
const FADE_LAYER: int = 100
const FADE_IN_DURATION: float = 1.2
const FADE_OUT_DURATION: float = 0.6
const TITLE_FLICKER_LOW: float = 0.72
const TITLE_FLICKER_PERIOD: float = 0.9

# ─── State ─────────────────────────────────────────
@onready var _start_button: Button = $Center/VBox/StartButton
@onready var _vbox: VBoxContainer = $Center/VBox

var _options: OptionsPanel
var _fade: ColorRect

func _ready() -> void:
	MetaProgression.load_progress()
	$Center/VBox/StartButton.pressed.connect(_on_start_pressed)
	$Center/VBox/QuitButton.pressed.connect(_on_quit_pressed)
	_add_options_ui()
	_setup_fade()
	_animate_title()
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

## Overlay preto para fade-in (abrir) e fade-out (Iniciar).
func _setup_fade() -> void:
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = FADE_LAYER
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)
	add_child(fade_layer)
	create_tween().tween_property(_fade, "color:a", 0.0, FADE_IN_DURATION)

## Pulso sutil no título, como luz de fogo respirando.
func _animate_title() -> void:
	var title := $Center/VBox/Title
	var tween := create_tween().set_loops()
	tween.tween_property(title, "modulate:a", TITLE_FLICKER_LOW, TITLE_FLICKER_PERIOD) \
		.set_trans(Tween.TRANS_SINE)
	tween.tween_property(title, "modulate:a", 1.0, TITLE_FLICKER_PERIOD) \
		.set_trans(Tween.TRANS_SINE)

func _on_options_pressed() -> void:
	AudioDirector.unlock_audio()
	_options.open()

func _on_start_pressed() -> void:
	AudioDirector.unlock_audio()
	_start_button.disabled = true
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_OUT_DURATION)
	tween.tween_callback(func() -> void: GameState.change_screen(SignalBus.Screen.HUB))

func _on_quit_pressed() -> void:
	get_tree().quit()
