class_name Atmosphere
extends CanvasLayer

## Overlay de atmosfera (vinheta + grão de filme) por cima da cena. Espelha o
## padrão do DoomFire: um CanvasLayer com script que constrói tudo em código,
## sem material embutido em .tscn. Fica num layer alto para cobrir o jogo.
## O color-grade global é responsabilidade do CanvasModulate da cena.

# ─── Constants ─────────────────────────────────────
const SHADER_PATH: String = "res://assets/shaders/atmosphere.gdshader"
const OVERLAY_LAYER: int = 50

# ─── State ─────────────────────────────────────────
var _rect: ColorRect

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	layer = OVERLAY_LAYER

	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)

	_rect = ColorRect.new()
	_rect.material = mat
	_rect.color = Color(1, 1, 1, 1)  # cor base ignorada; o shader define a saída
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)
