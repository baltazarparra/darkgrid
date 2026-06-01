extends Node

# Manages high-level game state: current screen and pause.
# Emits changes through SignalBus so UI and scenes react.

# ─── State ─────────────────────────────────────────
var current_screen: SignalBus.Screen = SignalBus.Screen.MAIN_MENU
var is_paused: bool = false

# Inimigo do próximo combate. Se != null, o ArenaManager o usa e reseta.
# Ponto único para a Fase 4 (hub) escolher encontros (ex: Boss).
var next_enemy_scene: PackedScene = null

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
		SignalBus.Screen.WIN:
			get_tree().change_scene_to_file("res://scenes/ui/win.tscn")
		SignalBus.Screen.GAME_OVER:
			get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")
