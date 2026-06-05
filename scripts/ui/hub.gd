class_name Hub
extends CanvasLayer

## Acampamento entre runs: recupera HP, mostra fragmentos e deixa a Caipora carregar o
## CACHIMBO com ERVAS (aprimoramentos). Duas trilhas — Fúria (dano) e Cura (HP) — exibidas
## como cards rolável, montados de forma data-driven a partir de MetaProgression.UPGRADE_DEFS.

const FADE_LAYER: int = 100
const FADE_IN_DURATION: float = 0.8

# Paleta da tela (espelha options_panel.gd / constants.gd — bordas duras, sem arredondar).
const PANEL_BG := Color(0.075, 0.055, 0.055, 0.92)
const PANEL_BG_LOCKED := Color(0.05, 0.045, 0.05, 0.9)
const FURIA_ACCENT := Color(1.0, 0.42, 0.0, 1.0)    # âmbar/fogo
const CURA_ACCENT := Color(0.30, 0.52, 0.28, 1.0)   # verde folha
const LOCKED_ACCENT := Color(0.22, 0.18, 0.18, 1.0)
const TEXT := Color(0.788, 0.82, 0.851, 1.0)
const TEXT_DIM := Color(0.55, 0.55, 0.58, 1.0)
const DIM_MODULATE := Color(1, 1, 1, 0.45)

@onready var _stats: Label = $Center/VBox/Stats
@onready var _upgrade_list: VBoxContainer = $Center/VBox/UpgradeList
@onready var _enter_button: Button = $Center/VBox/EnterButton

var _options: OptionsPanel
var _fade: ColorRect
var _scale: float = 1.0

# Widgets por erva (key → {panel, name, info, button}), para o refresh central.
var _cards: Dictionary = {}
var _loaded_row: HBoxContainer       # ícones das ervas já carregadas no cachimbo
var _bonus_label: Label              # resumo "Fúria +X dano • Cura +Y HP"

func _ready() -> void:
	_setup_fade()
	_scale = _ui_scale()
	GameState.heal_to_full()
	_apply_scale_to_scene_nodes()
	_refresh_stats()
	_build_camp()
	_enter_button.pressed.connect(_on_enter_pressed)
	_add_options_ui()
	_enter_button.grab_focus()

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

# Retorna um fator de escala para compensar viewports portrait com CSS scale baixo.
# Em portrait mobile (css_scale ≈ 0.305) retorna ~1.64; em landscape retorna 1.0.
func _ui_scale() -> float:
	var win := Vector2(DisplayServer.window_get_size())
	if win.x <= 0.0 or win.y <= 0.0:
		return 1.0
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return 1.0
	var css_per_lp := minf(win.x / vp.x, win.y / vp.y)
	return maxf(1.0, 0.5 / css_per_lp)

func _apply_scale_to_scene_nodes() -> void:
	var s := _scale
	($Center/VBox/Title as Label).add_theme_font_size_override("font_size", roundi(28.0 * s))
	_stats.add_theme_font_size_override("font_size", roundi(16.0 * s))
	_enter_button.custom_minimum_size = Vector2(0.0, roundi(84.0 * s))
	_enter_button.add_theme_font_size_override("font_size", roundi(22.0 * s))

## Botão "Opções" (abaixo de Entrar na Floresta) + overlay, montados em código.
func _add_options_ui() -> void:
	_options = OptionsPanel.new()
	add_child(_options)

	var options_button := Button.new()
	options_button.text = "Opções"
	options_button.add_theme_font_size_override("font_size", roundi(16.0 * _scale))
	options_button.custom_minimum_size = Vector2(0, roundi(48.0 * _scale))
	options_button.pressed.connect(_on_options_pressed)
	$Center/VBox.add_child(options_button)

func _on_options_pressed() -> void:
	_options.open()

func _refresh_stats() -> void:
	_stats.text = "Caçadas: %d    Vitórias: %d" % [MetaProgression.total_runs, MetaProgression.total_wins]

# ─── Montagem da tela (cachimbo + trilhas roláveis) ────────────────────────────
func _build_camp() -> void:
	var vbox := _upgrade_list.get_parent() as VBoxContainer

	# Cabeçalho: cachimbo + ervas carregadas + resumo de bônus.
	var header := _build_cachimbo_header()
	vbox.add_child(header)
	vbox.move_child(header, _upgrade_list.get_index())

	# Lista rolável com as duas trilhas de cards.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var vp := get_viewport().get_visible_rect().size
	var col_w := clampf(vp.x * 0.92, 300.0, 600.0)
	# Altura limitada para sobrar espaço ao cachimbo, título e botões (CenterContainer
	# dimensiona ao mínimo do filho; o conteúdo rola dentro do ScrollContainer).
	var scroll_h := clampf(vp.y * 0.48, 200.0, 640.0)
	scroll.custom_minimum_size = Vector2(col_w, scroll_h)

	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", roundi(18.0 * _scale))
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(lines)

	lines.add_child(_build_section("FÚRIA — ervas de dano", FURIA_ACCENT, MetaProgression.FURIA_KEYS, col_w))
	lines.add_child(_build_section("CURA — ervas de vida", CURA_ACCENT, MetaProgression.CURA_KEYS, col_w))

	vbox.add_child(scroll)
	vbox.move_child(scroll, _upgrade_list.get_index())
	_upgrade_list.queue_free()  # placeholder do .tscn não é mais usado

	_refresh_all()

func _build_cachimbo_header() -> Control:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", roundi(6.0 * _scale))

	var pipe := TextureRect.new()
	pipe.texture = load("res://assets/sprites/cachimbo.png")
	pipe.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pipe.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pipe.custom_minimum_size = Vector2(roundi(144.0 * _scale), roundi(96.0 * _scale))
	pipe.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(pipe)

	_loaded_row = HBoxContainer.new()
	_loaded_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_loaded_row.add_theme_constant_override("separation", roundi(4.0 * _scale))
	_loaded_row.custom_minimum_size = Vector2(0, roundi(26.0 * _scale))
	box.add_child(_loaded_row)

	_bonus_label = Label.new()
	_bonus_label.add_theme_font_size_override("font_size", roundi(15.0 * _scale))
	_bonus_label.add_theme_color_override("font_color", TEXT)
	_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_bonus_label)
	return box

func _build_section(title: String, accent: Color, keys: Array, col_w: float) -> Control:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", roundi(8.0 * _scale))
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", roundi(16.0 * _scale))
	header.add_theme_color_override("font_color", accent)
	section.add_child(header)

	for key in keys:
		var def: Dictionary = MetaProgression.UPGRADE_DEFS[key]
		# Só constrói o card quando a fase exigida já foi alcançada (gate de UI).
		if MetaProgression.phase_reached < int(def.get("phase", 1)):
			continue
		section.add_child(_build_erva_card(key, accent, col_w))
	return section

func _build_erva_card(key: String, accent: Color, col_w: float) -> Control:
	var def: Dictionary = MetaProgression.UPGRADE_DEFS[key]

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(col_w, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = accent
	style.set_border_width_all(2)
	style.set_content_margin_all(roundi(10.0 * _scale))
	panel.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", roundi(12.0 * _scale))
	panel.add_child(row)

	var icon := TextureRect.new()
	icon.texture = load(String(def["icon"]))
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_px := roundi(48.0 * _scale)
	icon.custom_minimum_size = Vector2(icon_px, icon_px)
	row.add_child(icon)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info)

	var name_label := Label.new()
	name_label.text = String(def["name"])
	name_label.add_theme_font_size_override("font_size", roundi(19.0 * _scale))
	name_label.add_theme_color_override("font_color", TEXT)
	info.add_child(name_label)

	var info_label := Label.new()
	info_label.add_theme_font_size_override("font_size", roundi(13.0 * _scale))
	info_label.add_theme_color_override("font_color", TEXT_DIM)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(info_label)

	var button := Button.new()
	button.text = "Fumar"
	button.add_theme_font_size_override("font_size", roundi(18.0 * _scale))
	button.custom_minimum_size = Vector2(roundi(110.0 * _scale), roundi(50.0 * _scale))
	button.pressed.connect(_on_buy_pressed.bind(key))
	row.add_child(button)

	_cards[key] = {
		"panel": panel, "style": style, "name": name_label,
		"info": info_label, "button": button, "accent": accent,
	}
	return panel

# ─── Refresh ───────────────────────────────────────────────────────────────────
func _on_buy_pressed(key: String) -> void:
	if MetaProgression.purchase_upgrade(key):
		_refresh_all()

func _refresh_all() -> void:
	for key in _cards:
		_refresh_card(key)
	_refresh_header()

func _refresh_card(key: String) -> void:
	var def: Dictionary = MetaProgression.UPGRADE_DEFS[key]
	var card: Dictionary = _cards[key]
	var info_label: Label = card["info"]
	var button: Button = card["button"]
	var panel: PanelContainer = card["panel"]
	var style: StyleBoxFlat = card["style"]
	var accent: Color = card["accent"]

	var frags := int(MetaProgression.fragments)
	var cost := int(def.get("fragment_cost", 0))
	var owned := MetaProgression.get_upgrade_level(key) >= 1
	var req := String(def.get("requires", ""))
	var req_met := req == "" or MetaProgression.get_upgrade_level(req) >= 1

	if owned:
		info_label.text = "[NO CACHIMBO]"
		info_label.add_theme_color_override("font_color", accent)
		button.visible = false
		panel.modulate = Color.WHITE
		style.bg_color = PANEL_BG
		style.border_color = accent
	elif not req_met:
		var req_name := String(MetaProgression.UPGRADE_DEFS[req]["name"])
		info_label.text = "🔒 requer %s" % req_name
		info_label.add_theme_color_override("font_color", TEXT_DIM)
		button.visible = true
		button.disabled = true
		panel.modulate = DIM_MODULATE
		style.bg_color = PANEL_BG_LOCKED
		style.border_color = LOCKED_ACCENT
	else:
		info_label.text = "%s  •  Fragmentos: %d / %d" % [String(def.get("effect", "")), frags, cost]
		info_label.add_theme_color_override("font_color", TEXT_DIM)
		button.visible = true
		button.disabled = frags < cost
		panel.modulate = Color.WHITE
		style.bg_color = PANEL_BG
		style.border_color = accent

func _refresh_header() -> void:
	# Resumo de bônus.
	_bonus_label.text = "Fúria +%d dano   •   Cura +%d HP" % [
		MetaProgression.get_damage_bonus(), MetaProgression.get_health_bonus()
	]
	# Ícones das ervas já carregadas no cachimbo.
	for child in _loaded_row.get_children():
		child.queue_free()
	var any := false
	for key in MetaProgression.UPGRADE_DEFS:
		if MetaProgression.get_upgrade_level(key) < 1:
			continue
		any = true
		var dot := TextureRect.new()
		dot.texture = load(String(MetaProgression.UPGRADE_DEFS[key]["icon"]))
		dot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var px := roundi(24.0 * _scale)
		dot.custom_minimum_size = Vector2(px, px)
		_loaded_row.add_child(dot)
	if not any:
		var empty := Label.new()
		empty.text = "cachimbo vazio"
		empty.add_theme_font_size_override("font_size", roundi(12.0 * _scale))
		empty.add_theme_color_override("font_color", TEXT_DIM)
		_loaded_row.add_child(empty)

func _on_enter_pressed() -> void:
	if GameState.run_active:
		# Acampamento ENTRE fases: continua a run na próxima exploração pendente,
		# definida por GameState.advance_phase_via_hub() no avanço de fase.
		GameState.change_screen(GameState.pending_exploration)
	else:
		# Acampamento pós-derrota (santuário): a run acabou — começa uma caçada nova.
		GameState.start_run()
		GameState.change_screen(SignalBus.Screen.EXPLORATION)
