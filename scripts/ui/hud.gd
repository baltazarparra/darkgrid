class_name Hud
extends CanvasLayer

# ─── Exports ───────────────────────────────────────
@export var show_enemy_hp: bool = true

# ─── Constants ─────────────────────────────────────
# HP responsivo: cada fileira de ícones cabe numa fração da largura, ficando grande com
# poucos HP e encolhendo quando há muitos (jogador cresce +1/vitória; boss = 10).
const ICON_ALLOT_FRAC: float = 0.40
const ICON_SPACING_MAX: float = 64.0
const ICON_RADIUS_MIN: float = 12.0
const ICON_RADIUS_MAX: float = 32.0
const PLAYER_EMPTY := Constants.COLOR_BLOOD_EMPTY
const ENEMY_EMPTY := Constants.COLOR_AMBER_EMPTY

# ─── State ─────────────────────────────────────────
var _player_icons: HealthIcons
var _enemy_icons: HealthIcons
var _frag_label: Label

func _ready() -> void:
	var hbox: HBoxContainer = $Margin/HBox
	for child in hbox.get_children():
		child.queue_free()

	_player_icons = HealthIcons.new()
	var pm: Vector2 = _metrics_for(GameState.caipora_max_hp)
	_player_icons.setup(
		GameState.caipora_max_hp,
		HealthIcons.Shape.PENTAGRAM,
		Constants.COLOR_BLOOD,
		PLAYER_EMPTY, pm.x, pm.y
	)
	_player_icons.set_current(GameState.caipora_current_hp)
	hbox.add_child(_player_icons)

	_frag_label = Label.new()
	_frag_label.add_theme_font_size_override("font_size", _frag_font_size())
	_frag_label.add_theme_color_override("font_color", Constants.COLOR_AMBER)
	_frag_label.text = "+".repeat(MetaProgression.fragments)
	hbox.add_child(_frag_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	if show_enemy_hp:
		_enemy_icons = HealthIcons.new()
		var em: Vector2 = _metrics_for(Constants.ENEMY_MAX_HEALTH)
		_enemy_icons.setup(
			Constants.ENEMY_MAX_HEALTH,
			HealthIcons.Shape.STAR_OF_DAVID,
			Constants.COLOR_AMBER,
			ENEMY_EMPTY, em.x, em.y
		)
		hbox.add_child(_enemy_icons)

	_apply_safe_margins()
	get_viewport().size_changed.connect(_on_viewport_resized)

	SignalBus.caipora_health_changed.connect(_on_caipora_health_changed)
	SignalBus.enemy_health_changed.connect(_on_enemy_health_changed)
	SignalBus.fragment_gained.connect(_on_fragment_gained)
	SignalBus.chest_opened.connect(_on_chest_opened)

# ─── Layout responsivo ─────────────────────────────
## Retorna Vector2(radius, spacing) para uma fileira com `total` ícones, cabendo na
## largura alocada (ICON_ALLOT_FRAC da viewport).
func _metrics_for(total: int) -> Vector2:
	var vp := get_viewport().get_visible_rect().size
	var allotted: float = vp.x * ICON_ALLOT_FRAC
	var spacing: float = clampf(allotted / float(maxi(total, 1)), 0.0, ICON_SPACING_MAX)
	var radius: float = clampf(spacing * 0.42, ICON_RADIUS_MIN, ICON_RADIUS_MAX)
	return Vector2(radius, spacing)

func _frag_font_size() -> int:
	var vp := get_viewport().get_visible_rect().size
	return int(clampf(minf(vp.x, vp.y) * 0.03, 14.0, 28.0))

func _apply_safe_margins() -> void:
	var margin: MarginContainer = $Margin
	var vp := get_viewport().get_visible_rect().size
	var side: int = int(clampf(minf(vp.x, vp.y) * 0.055, 40.0, 80.0))
	var top: int = int(clampf(minf(vp.x, vp.y) * 0.05, 28.0, 64.0))
	margin.add_theme_constant_override("margin_left", side)
	margin.add_theme_constant_override("margin_right", side)
	margin.add_theme_constant_override("margin_top", top)

func _on_viewport_resized() -> void:
	_apply_safe_margins()
	if _player_icons != null:
		var pm: Vector2 = _metrics_for(_player_icons._total)
		_player_icons.set_metrics(pm.x, pm.y)
	if _enemy_icons != null:
		var em: Vector2 = _metrics_for(_enemy_icons._total)
		_enemy_icons.set_metrics(em.x, em.y)
	if _frag_label != null:
		_frag_label.add_theme_font_size_override("font_size", _frag_font_size())

func _on_caipora_health_changed(new_health: float, max_health: float) -> void:
	if max_health != _player_icons._total:
		var pm: Vector2 = _metrics_for(int(max_health))
		_player_icons.setup(
			max_health,
			HealthIcons.Shape.PENTAGRAM,
			Constants.COLOR_BLOOD,
			PLAYER_EMPTY, pm.x, pm.y
		)
	_player_icons.set_current(new_health)

func _on_enemy_health_changed(new_health: float, max_health: float) -> void:
	if not show_enemy_hp:
		return
	if max_health != _enemy_icons._total:
		var em: Vector2 = _metrics_for(int(max_health))
		_enemy_icons.setup(
			max_health,
			HealthIcons.Shape.STAR_OF_DAVID,
			Constants.COLOR_AMBER,
			ENEMY_EMPTY, em.x, em.y
		)
	_enemy_icons.set_current(new_health)

func _on_fragment_gained(total: int) -> void:
	_frag_label.text = "+".repeat(total)
	_show_fragment_popup()

func _on_chest_opened() -> void:
	_show_popup("+1 HP", Constants.COLOR_BLOOD)

func _show_fragment_popup() -> void:
	_show_popup("+1 fragmento", Constants.COLOR_AMBER)

func _show_popup(text: String, color: Color) -> void:
	var popup := Label.new()
	popup.text = text
	popup.add_theme_font_size_override("font_size", _frag_font_size() + 4)
	popup.add_theme_color_override("font_color", color)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.position = Vector2(-80.0, 40.0)
	add_child(popup)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 48.0, 1.5)
	tween.tween_property(popup, "modulate:a", 0.0, 1.5)
	tween.chain().tween_callback(popup.queue_free)
