class_name HubPickup
extends Node2D

# Erva no chão do acampamento: ícone do aprimoramento + custo em fragmentos. Pisar nela
# (tratado pelo HubManager) tenta a compra via MetaProgression.purchase_upgrade — fonte
# única da economia. Estado visual simples: ACESSÍVEL (custo âmbar, ícone vivo) vs. CARA
# (custo em sangue, ícone esmaecido). O brilho pulsante e o número flutuante vêm na Etapa 3.

const T: int = Constants.TILE_SIZE
const ICON_MARGIN: int = 6           # folga do ícone dentro do tile
const DIM_ALPHA: float = 0.45        # ícone esmaecido quando o jogador não pode pagar

var key: String
var cost: int

var _icon: Sprite2D
var _cost_label: Label

func setup(erva_key: String, grid_pos: Vector2i) -> void:
	key = erva_key
	var def: Dictionary = MetaProgression.UPGRADE_DEFS[key]
	cost = int(def.get("fragment_cost", 0))
	position = Vector2(grid_pos) * T

	_icon = Sprite2D.new()
	_icon.texture = load(String(def["icon"]))
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.position = Vector2(T, T) * 0.5  # Sprite2D é centralizado por padrão
	_fit_icon()
	add_child(_icon)

	# Custo logo abaixo do ícone, centrado no tile.
	_cost_label = Label.new()
	_cost_label.text = str(cost)
	_cost_label.add_theme_font_size_override("font_size", 8)
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost_label.size = Vector2(T, 0)
	_cost_label.position = Vector2(0, T - 10)
	add_child(_cost_label)

# Escala o ícone para caber no tile (assets podem exceder 32px).
func _fit_icon() -> void:
	var tex := _icon.texture
	if tex == null:
		return
	var longest: int = maxi(tex.get_width(), tex.get_height())
	if longest <= 0:
		return
	var s := float(T - ICON_MARGIN) / float(longest)
	_icon.scale = Vector2(s, s)

## Atualiza o estado visual conforme o jogador pode (ou não) pagar a erva.
func set_affordable(affordable: bool) -> void:
	if affordable:
		_icon.modulate = Color.WHITE
		_cost_label.add_theme_color_override("font_color", Constants.COLOR_AMBER)
	else:
		_icon.modulate = Color(1.0, 1.0, 1.0, DIM_ALPHA)
		_cost_label.add_theme_color_override("font_color", Constants.COLOR_BLOOD)

## Comprada: some do chão (fumada no cachimbo) e se libera.
func consume() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)

## Sem fragmento suficiente: pisca o custo em sangue (não compra, erva permanece).
func deny() -> void:
	_cost_label.add_theme_color_override("font_color", Constants.COLOR_BLOOD)
	var tween := create_tween()
	tween.tween_property(_cost_label, "modulate:a", 0.2, 0.12)
	tween.tween_property(_cost_label, "modulate:a", 1.0, 0.12)
