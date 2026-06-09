class_name HubCard
extends Button

# Card grande e clicável de UMA erva de aprimoramento no Hub: ícone + nome + efeito derivado
# (ex: "Dano +1/hit (total 2)") + custo em fragmentos. Clicar/tocar pede a compra ao HubShop
# (que valida via MetaProgression.purchase_upgrade — fonte única). Estado visual ACESSÍVEL
# (borda âmbar viva, custo âmbar, respiro pulsante) vs. CARO (borda apagada, custo em sangue).
# É um Button: foco por teclado/D-pad e clique/toque de graça; o conteúdo (VBox) ignora o mouse
# para os cliques caírem no botão.

const ICON_PX: int = 60               # lado do ícone no topo do card
const CARD_MIN := Vector2(330, 200)   # tamanho confortável de leitura/toque (paisagem, base 1280×720)
# Em retrato o card é largo (quase toda a tela) e mais baixo — a pilha vertical de duas
# trilhas precisa caber na altura sem rolar. A largura real vem do HubShop em relayout().
const CARD_HEIGHT_PORTRAIT := 156
const BORDER := 3                     # bordas duras (sem cantos arredondados — guia de UI)
# Fonte do nome entre MD(18) e LG(28): a fonte pixelada é larga, então 28 estoura a largura do
# card; 22 mantém os nomes curtos numa linha (os longos quebram no hífen, leitura natural).
const NAME_FONT: int = 22

var key: String
var cost: int

var _icon: TextureRect
var _name_label: Label
var _effect_label: Label
var _cost_label: Label
var _pulse: Tween
var _affordable: bool = false

# StyleBoxes reaproveitados entre estados (acessível vs. caro).
var _style_afford: StyleBoxFlat
var _style_locked: StyleBoxFlat

func setup(erva_key: String) -> void:
	key = erva_key
	var def: Dictionary = MetaProgression.UPGRADE_DEFS[key]
	cost = int(def.get("fragment_cost", 0))

	custom_minimum_size = CARD_MIN
	# Clique/toque apenas: sem foco de teclado, pra não sequestrar as setas (ui_left/right/up/
	# down) que movem a Caipora pelo acampamento nem comprar por engano com Enter.
	focus_mode = Control.FOCUS_NONE
	clip_text = false
	_build_styles()

	# Conteúdo vertical dentro do botão (ícone → nome → efeito → custo). Tudo ignora o mouse
	# para o clique cair no Button. Layout em coluna evita cortar o nome em fonte grande.
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)

	_icon = TextureRect.new()
	_icon.texture = load(String(def["icon"]))
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.custom_minimum_size = Vector2(ICON_PX, ICON_PX)
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_icon)

	_name_label = Label.new()
	_name_label.text = String(def.get("name", key))
	_name_label.add_theme_font_size_override("font_size", NAME_FONT)
	_name_label.add_theme_color_override("font_color", Constants.COLOR_TEXT)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_name_label)

	# Efeito derivado da matemática (fonte única — KI-006).
	_effect_label = Label.new()
	_effect_label.text = MetaProgression.effect_text(key)
	_effect_label.add_theme_font_size_override("font_size", Constants.FONT_MD)
	_effect_label.add_theme_color_override("font_color", Constants.COLOR_TEXT)
	_effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_effect_label)

	# Custo em fragmentos, rodapé do card.
	_cost_label = Label.new()
	_cost_label.text = "%d fragmentos" % cost
	_cost_label.add_theme_font_size_override("font_size", Constants.FONT_MD)
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_cost_label)

# Dois styleboxes de borda dura: âmbar quando dá pra pagar, apagado quando não.
func _build_styles() -> void:
	_style_afford = StyleBoxFlat.new()
	_style_afford.bg_color = Color(0.06, 0.05, 0.04, 0.92)
	_style_afford.border_color = Constants.COLOR_AMBER
	_style_afford.set_border_width_all(BORDER)
	_style_afford.set_content_margin_all(16)

	_style_locked = StyleBoxFlat.new()
	_style_locked.bg_color = Color(0.05, 0.04, 0.045, 0.88)
	_style_locked.border_color = Color(0.35, 0.18, 0.18, 0.9)
	_style_locked.set_border_width_all(BORDER)
	_style_locked.set_content_margin_all(16)

## Atualiza o estado visual conforme o jogador pode (ou não) pagar a erva. Acessível ganha
## borda âmbar, custo âmbar e respiro pulsante; cara fica apagada com custo em sangue.
func set_affordable(affordable: bool) -> void:
	_affordable = affordable
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
		_pulse = null
	modulate = Color.WHITE
	var style := _style_afford if affordable else _style_locked
	for slot: String in ["normal", "hover", "pressed", "focus"]:
		add_theme_stylebox_override(slot, style)
	if affordable:
		_cost_label.add_theme_color_override("font_color", Constants.COLOR_AMBER)
		_pulse = create_tween().set_loops()
		_pulse.tween_property(self, "modulate", Color(1.12, 1.12, 1.12, 1.0), 0.8).set_trans(Tween.TRANS_SINE)
		_pulse.tween_property(self, "modulate", Color.WHITE, 0.8).set_trans(Tween.TRANS_SINE)
	else:
		_cost_label.add_theme_color_override("font_color", Constants.COLOR_BLOOD)

## Reajusta o card à orientação/largura corrente (chamado pelo HubShop em size_changed). Em
## retrato o card fica largo e baixo (cabe a pilha de duas trilhas); em paisagem volta ao
## tamanho confortável de coluna. A largura é imposta como mínimo e o Button preenche a coluna.
func relayout(width: float, portrait: bool) -> void:
	var h: float = float(CARD_HEIGHT_PORTRAIT) if portrait else CARD_MIN.y
	custom_minimum_size = Vector2(width, h)
	size_flags_horizontal = Control.SIZE_FILL

## Comprada: encolhe e some (fumada no cachimbo) e se libera.
func consume() -> void:
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
		_pulse = null
	disabled = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_property(self, "scale", Vector2(0.92, 0.92), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)

## Sem fragmento suficiente: pisca o custo em sangue (não compra, card permanece).
func deny() -> void:
	_cost_label.add_theme_color_override("font_color", Constants.COLOR_BLOOD)
	var tween := create_tween()
	tween.tween_property(_cost_label, "modulate:a", 0.2, 0.12)
	tween.tween_property(_cost_label, "modulate:a", 1.0, 0.12)
