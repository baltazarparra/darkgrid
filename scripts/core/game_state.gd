extends Node

# Manages high-level game state: current screen and pause.
# Emits changes through SignalBus so UI and scenes react.

# ─── State ─────────────────────────────────────────
var current_screen: SignalBus.Screen = SignalBus.Screen.MAIN_MENU
var is_paused: bool = false

# ─── Public API ────────────────────────────────────
func change_screen(new_screen: SignalBus.Screen) -> void:
	current_screen = new_screen
	SignalBus.screen_changed.emit(new_screen)

func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
