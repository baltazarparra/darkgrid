class_name Atmosphere
extends CanvasLayer

## Overlay de atmosfera (vinheta + grão de filme) por cima da cena. Espelha o
## padrão do DoomFire: um CanvasLayer com script que constrói tudo em código,
## sem material embutido em .tscn. Fica num layer alto para cobrir o jogo.
##
## Color grading (gradient map por fase, Constants.GRADING_*): vive numa
## CanvasLayer FILHA em layer 0 — captura só o mundo (acima do canvas implícito,
## abaixo do HUD layer 1 e do D-pad layer 20), então a UI não é graduada.
## O grade grosso por CanvasModulate continua sendo da cena; a LUT refina.

# ─── Constants ─────────────────────────────────────
const SHADER_PATH: String = "res://assets/shaders/atmosphere.gdshader"
const GRADE_SHADER_PATH: String = "res://shaders/gradient_map.gdshader"
const OVERLAY_LAYER: int = 50

# ─── State ─────────────────────────────────────────
var _rect: ColorRect

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	layer = OVERLAY_LAYER

	if _grading_active():
		_setup_grading()

	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)

	_rect = ColorRect.new()
	_rect.material = mat
	_rect.color = Color(1, 1, 1, 1)  # cor base ignorada; o shader define a saída
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)

# ─── Color grading ─────────────────────────────────
func _grading_active() -> bool:
	if not Constants.GRADING_ENABLED:
		return false
	# Web fica desligado até validação de FPS em dispositivo real (Safari iPhone
	# é o piso) — SCREEN_TEXTURE custa caro em gl_compatibility.
	if OS.has_feature("web") and not Constants.GRADING_ON_WEB:
		return false
	return true

func _setup_grading() -> void:
	var lut_path := "res://assets/sprites/grade_p%d.png" % clampi(GameState.active_phase, 1, 5)
	if not ResourceLoader.exists(lut_path):
		return
	var mat := ShaderMaterial.new()
	mat.shader = load(GRADE_SHADER_PATH)
	mat.set_shader_parameter("grade_lut", load(lut_path))
	mat.set_shader_parameter("mix_amount", Constants.GRADING_MIX)

	var grade_rect := ColorRect.new()
	grade_rect.material = mat
	grade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)

	var grade_layer := CanvasLayer.new()
	grade_layer.layer = 0
	grade_layer.add_child(grade_rect)
	add_child(grade_layer)
