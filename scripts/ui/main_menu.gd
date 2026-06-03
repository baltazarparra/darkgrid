class_name MainMenu
extends CanvasLayer

## Porta de entrada do jogo. Carrega o save no boot e roteia para o Hub.
## A abertura "Horizonte Infernal" (fogo, treelines, brasas, Caipora andando) é
## montada na cena; aqui cuidamos do fade-in/out e da vida do título.

# ─── Constants ─────────────────────────────────────
const FADE_LAYER: int = 100
const FADE_IN_DURATION: float = 1.2
const FADE_OUT_DURATION: float = 0.6
const TITLE_COLOR_PERIOD: float = 1.4

# ─── State ─────────────────────────────────────────
@onready var _start_button: Button = $Center/VBox/StartButton

var _fade: ColorRect

func _ready() -> void:
	MetaProgression.load_progress()
	$Center/VBox/StartButton.pressed.connect(_on_start_pressed)
	$Center/VBox/QuitButton.pressed.connect(_on_quit_pressed)
	_setup_fade()
	_animate_title()
	_start_button.grab_focus()

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

## Ciclo de brasa no título — escuro → médio → vivo → escuro.
func _animate_title() -> void:
	var title := $Center/VBox/Title as RichTextLabel
	var tween := create_tween().set_loops()
	tween.tween_property(title, "modulate", Constants.COLOR_FIRE_LOW, TITLE_COLOR_PERIOD / 3.0) \
		.set_trans(Tween.TRANS_SINE)
	tween.tween_property(title, "modulate", Constants.COLOR_FIRE_MID, TITLE_COLOR_PERIOD / 3.0) \
		.set_trans(Tween.TRANS_SINE)
	tween.tween_property(title, "modulate", Constants.COLOR_FIRE_HOT, TITLE_COLOR_PERIOD / 3.0) \
		.set_trans(Tween.TRANS_SINE)

func _on_start_pressed() -> void:
	AudioDirector.unlock_audio()
	_start_button.disabled = true
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_OUT_DURATION)
	tween.tween_callback(func() -> void: GameState.change_screen(SignalBus.Screen.HUB))

func _on_quit_pressed() -> void:
	get_tree().quit()
