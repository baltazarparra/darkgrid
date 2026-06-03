class_name Hub
extends CanvasLayer

## Santuário entre runs: recupera HP, exibe fragmentos, permite comprar upgrades.

const FADE_LAYER: int = 100
const FADE_IN_DURATION: float = 0.8

@onready var _stats: Label = $Center/VBox/Stats
@onready var _upgrade_list: VBoxContainer = $Center/VBox/UpgradeList
@onready var _enter_button: Button = $Center/VBox/EnterButton

var _options: OptionsPanel
var _fade: ColorRect
var _forca_label: Label
var _forca_button: Button
var _saude_label: Label
var _saude_button: Button
var _forca2_label: Label
var _forca2_button: Button
var _saude2_label: Label
var _saude2_button: Button
var _forca3_label: Label
var _forca3_button: Button
var _saude3_label: Label
var _saude3_button: Button

var _scale: float = 1.0

func _ready() -> void:
	_setup_fade()
	_scale = _ui_scale()
	GameState.heal_to_full()
	_apply_scale_to_scene_nodes()
	_refresh_stats()
	_build_forca_row()
	_build_saude_row()
	if MetaProgression.phase_reached >= 2:
		_build_forca2_row()
		_build_saude2_row()
	if MetaProgression.phase_reached >= 3:
		_build_forca3_row()
		_build_saude3_row()
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

# ─── Helpers de row ────────────────────────────────
func _make_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", roundi(16.0 * _scale))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	return row

func _make_upgrade_label() -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", roundi(21.0 * _scale))
	lbl.custom_minimum_size = Vector2(roundi(260.0 * _scale), 0)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl

func _make_buy_button() -> Button:
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", roundi(21.0 * _scale))
	btn.custom_minimum_size = Vector2(0, roundi(54.0 * _scale))
	btn.text = "Comprar"
	return btn

# ─── Força ─────────────────────────────────────────
func _build_forca_row() -> void:
	var row := _make_row()
	_forca_label = _make_upgrade_label()
	_forca_button = _make_buy_button()
	_forca_button.pressed.connect(_on_forca_pressed)
	row.add_child(_forca_label)
	row.add_child(_forca_button)
	_upgrade_list.add_child(row)
	_refresh_forca_row()

func _refresh_forca_row() -> void:
	var frags := int(MetaProgression.fragments)
	var level := MetaProgression.get_upgrade_level("forca")
	var maxed := level >= 1
	if maxed:
		_forca_label.text = "Força  [APRIMORADO]  Fragmentos: %d" % frags
	else:
		_forca_label.text = "Força  Dano +1/hit  Fragmentos: %d / 4" % frags
	_forca_button.disabled = maxed or frags < 4

func _on_forca_pressed() -> void:
	if MetaProgression.purchase_upgrade("forca"):
		_refresh_forca_row()
		_refresh_saude_row()
		if _forca2_label != null:
			_refresh_forca2_row()

# ─── Saúde ─────────────────────────────────────────
func _build_saude_row() -> void:
	var row := _make_row()
	_saude_label = _make_upgrade_label()
	_saude_button = _make_buy_button()
	_saude_button.pressed.connect(_on_saude_pressed)
	row.add_child(_saude_label)
	row.add_child(_saude_button)
	_upgrade_list.add_child(row)
	_refresh_saude_row()

func _refresh_saude_row() -> void:
	var forca_comprada := MetaProgression.get_upgrade_level("forca") >= 1
	var frags := int(MetaProgression.fragments)
	var level := MetaProgression.get_upgrade_level("saude")
	var maxed := level >= 1
	_saude_label.get_parent().visible = forca_comprada
	if not forca_comprada:
		return
	if maxed:
		_saude_label.text = "Saúde  [APRIMORADO]  Fragmentos: %d" % frags
	else:
		_saude_label.text = "Saúde  +2 HP (permanente)  Fragmentos: %d / 6" % frags
	_saude_button.disabled = maxed or frags < 6

func _on_saude_pressed() -> void:
	if MetaProgression.purchase_upgrade("saude"):
		_refresh_saude_row()

# ─── Força 2 ───────────────────────────────────────
func _build_forca2_row() -> void:
	var row := _make_row()
	_forca2_label = _make_upgrade_label()
	_forca2_button = _make_buy_button()
	_forca2_button.pressed.connect(_on_forca2_pressed)
	row.add_child(_forca2_label)
	row.add_child(_forca2_button)
	_upgrade_list.add_child(row)
	_refresh_forca2_row()

func _refresh_forca2_row() -> void:
	var forca_comprada := MetaProgression.get_upgrade_level("forca") >= 1
	var frags := int(MetaProgression.fragments)
	var level := MetaProgression.get_upgrade_level("forca_2")
	var maxed := level >= 1
	_forca2_label.get_parent().visible = forca_comprada
	if not forca_comprada:
		return
	if maxed:
		_forca2_label.text = "Fúria da Floresta  [APRIMORADO]  Fragmentos: %d" % frags
	else:
		_forca2_label.text = "Fúria da Floresta  Dano +1/hit (total 3)  Fragmentos: %d / 6" % frags
	_forca2_button.disabled = maxed or frags < 6 or not forca_comprada

func _on_forca2_pressed() -> void:
	if MetaProgression.purchase_upgrade("forca_2"):
		_refresh_forca2_row()

# ─── Saúde 2 ───────────────────────────────────────
func _build_saude2_row() -> void:
	var row := _make_row()
	_saude2_label = _make_upgrade_label()
	_saude2_button = _make_buy_button()
	_saude2_button.pressed.connect(_on_saude2_pressed)
	row.add_child(_saude2_label)
	row.add_child(_saude2_button)
	_upgrade_list.add_child(row)
	_refresh_saude2_row()

func _refresh_saude2_row() -> void:
	var frags := int(MetaProgression.fragments)
	var level := MetaProgression.get_upgrade_level("saude_2")
	var maxed := level >= 1
	if maxed:
		_saude2_label.text = "Pele de Árvore  [APRIMORADO]  Fragmentos: %d" % frags
	else:
		_saude2_label.text = "Pele de Árvore  +2 HP  Fragmentos: %d / 9" % frags
	_saude2_button.disabled = maxed or frags < 9

func _on_saude2_pressed() -> void:
	if MetaProgression.purchase_upgrade("saude_2"):
		_refresh_saude2_row()

# ─── Força 3 ───────────────────────────────────────
func _build_forca3_row() -> void:
	var row := _make_row()
	_forca3_label = _make_upgrade_label()
	_forca3_button = _make_buy_button()
	_forca3_button.pressed.connect(_on_forca3_pressed)
	row.add_child(_forca3_label)
	row.add_child(_forca3_button)
	_upgrade_list.add_child(row)
	_refresh_forca3_row()

func _refresh_forca3_row() -> void:
	var forca2_comprada := MetaProgression.get_upgrade_level("forca_2") >= 1
	var frags := int(MetaProgression.fragments)
	var level := MetaProgression.get_upgrade_level("forca_3")
	var maxed := level >= 1
	_forca3_label.get_parent().visible = forca2_comprada
	if not forca2_comprada:
		return
	if maxed:
		_forca3_label.text = "Fúria Ancestral  [APRIMORADO]  Fragmentos: %d" % frags
	else:
		_forca3_label.text = "Fúria Ancestral  Dano +1/hit (total 4)  Fragmentos: %d / 8" % frags
	_forca3_button.disabled = maxed or frags < 8 or not forca2_comprada

func _on_forca3_pressed() -> void:
	if MetaProgression.purchase_upgrade("forca_3"):
		_refresh_forca3_row()

# ─── Saúde 3 ───────────────────────────────────────
func _build_saude3_row() -> void:
	var row := _make_row()
	_saude3_label = _make_upgrade_label()
	_saude3_button = _make_buy_button()
	_saude3_button.pressed.connect(_on_saude3_pressed)
	row.add_child(_saude3_label)
	row.add_child(_saude3_button)
	_upgrade_list.add_child(row)
	_refresh_saude3_row()

func _refresh_saude3_row() -> void:
	var saude2_comprada := MetaProgression.get_upgrade_level("saude_2") >= 1
	var frags := int(MetaProgression.fragments)
	var level := MetaProgression.get_upgrade_level("saude_3")
	var maxed := level >= 1
	_saude3_label.get_parent().visible = saude2_comprada
	if not saude2_comprada:
		return
	if maxed:
		_saude3_label.text = "Raiz Viva  [APRIMORADO]  Fragmentos: %d" % frags
	else:
		_saude3_label.text = "Raiz Viva  +2 HP  Fragmentos: %d / 12" % frags
	_saude3_button.disabled = maxed or frags < 12 or not saude2_comprada

func _on_saude3_pressed() -> void:
	if MetaProgression.purchase_upgrade("saude_3"):
		_refresh_saude3_row()

func _on_enter_pressed() -> void:
	GameState.start_run()
	GameState.change_screen(SignalBus.Screen.EXPLORATION)
