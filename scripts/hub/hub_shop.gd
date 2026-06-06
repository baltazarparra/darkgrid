class_name HubShop
extends CanvasLayer

# Interface de aprimoramentos do Hub: cabeçalho com FRAGMENTOS + resumo de bônus + Opções, e
# os cards grandes e clicáveis das ervas disponíveis, agrupados por trilha (FÚRIA · dano e
# CURA · vida). Substitui as ervas pequenas no chão da Fase 9 por algo grande de ler/clicar/
# entender. purchase_upgrade continua a fonte única de custo/requires/persistência.
#
# Regra de pacing preservada da Etapa 2: o conjunto de cards é montado UMA vez na ENTRADA
# (available_keys). Comprar uma erva NÃO faz a próxima da cadeia aparecer nesta fogueira — ela
# "nasce na próxima fogueira" (a coluna mostra esse status). Os fundos ignoram o mouse para
# não engolir o D-pad de toque nem a caminhada até o rastro de saída.

# Sucesso/recusa de compra — o HubManager escuta para tocar o SFX (dono do SfxSystem).
signal purchased(key: String)
signal denied(key: String)

const HINT_COLOR := Color(0.55, 0.55, 0.58, 1.0)
const TITLE_FURIA := "FÚRIA · dano"
const TITLE_CURA := "CURA · vida"
const COLUMN_SEP := 48
const CARD_WIDTH := 330   # casa com HubCard.CARD_MIN.x (largura da coluna/status)

# ─── State ─────────────────────────────────────────
var _root: Control
var _frag_label: Label
var _bonus_label: Label
var _options: OptionsPanel
var _options_button: Button
var _margin: MarginContainer

# Colunas por trilha: { "furia"/"cura": { "vbox": VBox, "cards": Array[HubCard] } }.
var _columns: Dictionary = {}

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	layer = 10
	_build()

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_header()
	_build_cards()

	_options = OptionsPanel.new()
	add_child(_options)
	_options_button.pressed.connect(_options.open)

	_apply_safe_margins()
	get_viewport().size_changed.connect(_apply_safe_margins)
	refresh()

# Cabeçalho: [ fragmentos + bônus à esquerda ] ··· [ Opções à direita ].
func _build_header() -> void:
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.add_child(row)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(vbox)

	_frag_label = Label.new()
	_frag_label.add_theme_color_override("font_color", Constants.COLOR_AMBER)
	_frag_label.add_theme_font_size_override("font_size", Constants.FONT_LG)
	vbox.add_child(_frag_label)

	_bonus_label = Label.new()
	_bonus_label.add_theme_color_override("font_color", Constants.COLOR_TEXT)
	vbox.add_child(_bonus_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)

	_options_button = Button.new()
	_options_button.text = "Opções"
	_options_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_options_button)

# Corpo: as duas trilhas lado a lado, centradas (deixa o rodapé livre pro D-pad e o rastro).
func _build_cards() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 16)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(stack)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", COLUMN_SEP)
	columns.alignment = BoxContainer.ALIGNMENT_CENTER
	columns.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(columns)

	_columns["furia"] = _build_column(columns, TITLE_FURIA, MetaProgression.FURIA_KEYS)
	_columns["cura"] = _build_column(columns, TITLE_CURA, MetaProgression.CURA_KEYS)

	var hint := Label.new()
	hint.text = "clique na erva pra fumar • caminhe até o rastro pra entrar na mata"
	hint.add_theme_color_override("font_color", HINT_COLOR)
	hint.add_theme_font_size_override("font_size", Constants.FONT_SM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(hint)

# Uma trilha: título + os cards disponíveis (ou um status do que vem a seguir).
func _build_column(parent: HBoxContainer, title: String, keys: Array) -> Dictionary:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.custom_minimum_size = Vector2(CARD_WIDTH, 0)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(vbox)

	var heading := Label.new()
	heading.text = title
	heading.add_theme_color_override("font_color", Constants.COLOR_AMBER)
	heading.add_theme_font_size_override("font_size", Constants.FONT_MD)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(heading)

	var column := { "vbox": vbox, "cards": [] as Array }
	var avail := MetaProgression.available_keys(keys)
	if avail.is_empty():
		_add_status(column, keys)
	else:
		for key: String in avail:
			var card := HubCard.new()
			vbox.add_child(card)
			card.setup(key)
			card.pressed.connect(_on_card_pressed.bind(card))
			column["cards"].append(card)
	return column

# Status da trilha sem card disponível: o que vem a seguir (ou trilha completa).
func _add_status(column: Dictionary, keys: Array) -> void:
	var status := Label.new()
	status.text = _trilha_status_text(keys)
	status.add_theme_color_override("font_color", HINT_COLOR)
	status.add_theme_font_size_override("font_size", Constants.FONT_SM)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(CARD_WIDTH, 0)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column["vbox"].add_child(status)
	column["status"] = status

## Explica o próximo passo de uma trilha sem erva disponível: erva pendente travada por fase,
## travada pela regra desta-fogueira (requisito já cumprido) ou trilha completa.
func _trilha_status_text(keys: Array) -> String:
	var pending := MetaProgression.next_pending_key(keys)
	if pending == "":
		return "trilha completa"
	var def: Dictionary = MetaProgression.UPGRADE_DEFS[pending]
	var nm: String = String(def.get("name", pending))
	if MetaProgression.phase_reached < int(def.get("phase", 1)):
		return "próxima: %s — Fase %d" % [nm, int(def.get("phase", 1))]
	return "próxima: %s — na próxima fogueira" % nm

# ─── Compra ────────────────────────────────────────
func _on_card_pressed(card: HubCard) -> void:
	attempt_buy(card.key)

## Tenta comprar a erva `key` (mesmo caminho do clique). purchase_upgrade valida tudo e
## persiste. Em sucesso: card some, debita, atualiza HUD e demais cards; em falha (fragmento
## insuficiente): pisca o custo. Retorna true se comprou. Exposto para os testes.
func attempt_buy(key: String) -> bool:
	var card := _card_for(key)
	if card == null:
		return false
	if MetaProgression.purchase_upgrade(key):
		_spawn_floating_cost(card)
		_remove_card(card)
		card.consume()
		refresh()
		purchased.emit(key)
		return true
	card.deny()
	denied.emit(key)
	return false

func _card_for(key: String) -> HubCard:
	for line: String in _columns:
		for card: HubCard in _columns[line]["cards"]:
			if card.key == key:
				return card
	return null

# Tira o card da coluna; se a coluna esvaziou, mostra o status do que vem a seguir.
func _remove_card(card: HubCard) -> void:
	var line: String = String(MetaProgression.UPGRADE_DEFS[card.key].get("line", ""))
	if not _columns.has(line):
		return
	var column: Dictionary = _columns[line]
	column["cards"].erase(card)
	if column["cards"].is_empty():
		var keys: Array = MetaProgression.FURIA_KEYS if line == "furia" else MetaProgression.CURA_KEYS
		_add_status(column, keys)

## Reescreve fragmentos/bônus e re-avalia o brilho de cada card (comprar pode ter esvaziado o
## bolso). Fonte de verdade: MetaProgression.
func refresh() -> void:
	_frag_label.text = "Fragmentos: %d" % int(MetaProgression.fragments)
	_bonus_label.text = "Fúria +%d dano   Cura +%d HP" % [
		MetaProgression.get_damage_bonus(), MetaProgression.get_health_bonus()
	]
	for line: String in _columns:
		for card: HubCard in _columns[line]["cards"]:
			card.set_affordable(MetaProgression.fragments >= card.cost)

# Número flutuante "−custo" subindo do card (screen-space, sobre o _root).
func _spawn_floating_cost(card: HubCard) -> void:
	var label := Label.new()
	label.text = "-%d" % card.cost
	label.add_theme_font_size_override("font_size", Constants.FONT_LG)
	label.add_theme_color_override("font_color", Constants.COLOR_AMBER)
	label.position = card.global_position + Vector2(card.size.x * 0.5, 0.0)
	label.z_index = 5
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 48.0, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9)
	tween.chain().tween_callback(label.queue_free)

# ─── Para os testes / inspeção ─────────────────────
## Keys das ervas com card vivo agora (não compradas nesta fogueira).
func available_card_keys() -> Array[String]:
	var out: Array[String] = []
	for line: String in _columns:
		for card: HubCard in _columns[line]["cards"]:
			out.append(card.key)
	return out

# ─── Margens seguras (notch/safe-area; espelha o HUD antigo) ───
func _apply_safe_margins() -> void:
	var vp := get_viewport().get_visible_rect().size
	var top: int = int(clampf(minf(vp.x, vp.y) * 0.05, 28.0, 64.0))
	var side: int = int(clampf(minf(vp.x, vp.y) * 0.055, 40.0, 80.0))
	var fs: int = int(clampf(minf(vp.x, vp.y) * 0.024, 10.0, 18.0))
	_margin.add_theme_constant_override("margin_top", top)
	_margin.add_theme_constant_override("margin_left", side)
	_margin.add_theme_constant_override("margin_right", side)
	_bonus_label.add_theme_font_size_override("font_size", fs)
	_options_button.add_theme_font_size_override("font_size", fs)
