class_name Hud
extends CanvasLayer

## HUD de combate: barra de vida da Caipora. Desacoplado — escuta apenas o
## SignalBus, sem referenciar a Caipora diretamente.

@onready var _bar: ProgressBar = $Margin/HBox/HealthBar

func _ready() -> void:
	SignalBus.caipora_health_changed.connect(_on_health_changed)

func _on_health_changed(new_health: int, max_health: int) -> void:
	_bar.max_value = max_health
	_bar.value = new_health
