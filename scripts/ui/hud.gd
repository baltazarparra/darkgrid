class_name Hud
extends CanvasLayer

var _player_icons: HealthIcons
var _enemy_icons: HealthIcons

func _ready() -> void:
	var hbox: HBoxContainer = $Margin/HBox
	for child in hbox.get_children():
		child.queue_free()

	_player_icons = HealthIcons.new()
	_player_icons.setup(
		Constants.CAIPORA_MAX_HEALTH,
		HealthIcons.Shape.PENTAGRAM,
		Constants.COLOR_BLOOD,
		Color(0.25, 0.04, 0.04, 0.35)
	)
	hbox.add_child(_player_icons)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

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
	if max_health != _enemy_icons._total:
		_enemy_icons.setup(
			max_health,
			HealthIcons.Shape.STAR_OF_DAVID,
			Constants.COLOR_AMBER,
			Color(0.3, 0.18, 0.02, 0.35)
		)
	_enemy_icons.set_current(new_health)
