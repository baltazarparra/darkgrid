extends Node

# Manages high-level game state: current screen and pause.
# Emits changes through SignalBus so UI and scenes react.

# ─── State ─────────────────────────────────────────
var current_screen: SignalBus.Screen = SignalBus.Screen.MAIN_MENU
var is_paused: bool = false

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	SignalBus.screen_changed.connect(_on_screen_changed)

# ─── Public API ────────────────────────────────────
func change_screen(new_screen: SignalBus.Screen) -> void:
	current_screen = new_screen
	SignalBus.screen_changed.emit(new_screen)

func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused

# ─── Private ───────────────────────────────────────
func _on_screen_changed(new_screen: SignalBus.Screen) -> void:
	match new_screen:
		SignalBus.Screen.ARENA:
			get_tree().change_scene_to_file("res://scenes/arena/arena.tscn")
		SignalBus.Screen.EXPLORATION:
			get_tree().change_scene_to_file("res://scenes/exploration/exploration.tscn")
