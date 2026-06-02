class_name Hud
extends CanvasLayer

# ─── Exports ───────────────────────────────────────
@export var show_enemy_hp: bool = true

# ─── State ─────────────────────────────────────────
var _player_icons: HealthIcons
var _enemy_icons: HealthIcons
var _frag_label: Label

func _ready() -> void:
	var hbox: HBoxContainer = $Margin/HBox
	for child in hbox.get_children():
		child.queue_free()

	_player_icons = HealthIcons.new()
	_player_icons.setup(
		GameState.caipora_max_hp,
		HealthIcons.Shape.PENTAGRAM,
		Constants.COLOR_BLOOD,
		Color(0.25, 0.04, 0.04, 0.35)
	)
	_player_icons.set_current(GameState.caipora_current_hp)
	hbox.add_child(_player_icons)

	_frag_label = Label.new()
	_frag_label.add_theme_font_size_override("font_size", 14)
	_frag_label.add_theme_color_override("font_color", Constants.COLOR_AMBER)
	_frag_label.text = "+".repeat(MetaProgression.fragments)
	hbox.add_child(_frag_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	if show_enemy_hp:
		_enemy_icons = HealthIcons.new()
		_enemy_icons.setup(
			Constants.ENEMY_MAX_HEALTH,
			HealthIcons.Shape.STAR_OF_DAVID,
			Constants.COLOR_AMBER,
			Color(0.3, 0.18, 0.02, 0.35)
		)
		hbox.add_child(_enemy_icons)

	SignalBus.caipora_health_changed.connect(_on_caipora_health_changed)
	SignalBus.enemy_health_changed.connect(_on_enemy_health_changed)
	SignalBus.fragment_gained.connect(_on_fragment_gained)

func _on_caipora_health_changed(new_health: int, max_health: int) -> void:
	if max_health != _player_icons._total:
		_player_icons.setup(
			max_health,
			HealthIcons.Shape.PENTAGRAM,
			Constants.COLOR_BLOOD,
			Color(0.25, 0.04, 0.04, 0.35)
		)
	_player_icons.set_current(new_health)

func _on_enemy_health_changed(new_health: int, max_health: int) -> void:
	if not show_enemy_hp:
		return
	if max_health != _enemy_icons._total:
		_enemy_icons.setup(
			max_health,
			HealthIcons.Shape.STAR_OF_DAVID,
			Constants.COLOR_AMBER,
			Color(0.3, 0.18, 0.02, 0.35)
		)
	_enemy_icons.set_current(new_health)

func _on_fragment_gained(total: int) -> void:
	_frag_label.text = "+".repeat(total)
	_show_fragment_popup()

func _show_fragment_popup() -> void:
	var popup := Label.new()
	popup.text = "+1 fragmento"
	popup.add_theme_font_size_override("font_size", 18)
	popup.add_theme_color_override("font_color", Constants.COLOR_AMBER)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.position = Vector2(-80.0, 40.0)
	add_child(popup)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 48.0, 1.5)
	tween.tween_property(popup, "modulate:a", 0.0, 1.5)
	tween.chain().tween_callback(popup.queue_free)
