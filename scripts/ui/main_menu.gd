class_name MainMenu
extends CanvasLayer

## Porta de entrada do jogo. Roteia para o Hub (o save é carregado pelo autoload MetaProgression).
## A abertura "Horizonte Infernal" (fogo, treelines, brasas, Caipora andando) é
## montada na cena; aqui cuidamos do fade-in/out e da vida do título.

# ─── Constants ─────────────────────────────────────
const FADE_LAYER: int = 100
const FADE_IN_DURATION: float = 1.2
const FADE_OUT_DURATION: float = 0.6

# ─── State ─────────────────────────────────────────
@onready var _start_button: Button = $Center/VBox/StartButton

var _fade: ColorRect

func _ready() -> void:
	# O save é carregado no _ready() do autoload MetaProgression (independente da cena de boot).
	$Center/VBox/StartButton.pressed.connect(_on_start_pressed)
	$Center/VBox/QuitButton.pressed.connect(_on_quit_pressed)
	$Center/VBox/GithubLink.pressed.connect(_on_github_pressed)
	_setup_fade()
	_apply_title_shader()
	_setup_version_label()
	_start_button.grab_focus()

## Versão atual (canto inferior direito), lida de application/config/version.
func _setup_version_label() -> void:
	var label := Label.new()
	label.text = str(ProjectSettings.get_setting("application/config/version", "dev"))
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.494, 0.514, 0.541, 0.7))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	label.position -= Vector2(12, 10)
	add_child(label)

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

func _apply_title_shader() -> void:
	var title := $Center/VBox/Title as RichTextLabel
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/title_fire.gdshader") as Shader
	title.material = mat

func _on_start_pressed() -> void:
	AudioDirector.unlock_audio()
	_start_button.disabled = true
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_OUT_DURATION)
	tween.tween_callback(func() -> void: GameState.change_screen(SignalBus.Screen.HUB))

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_github_pressed() -> void:
	OS.shell_open("https://github.com/baltazarparra")
