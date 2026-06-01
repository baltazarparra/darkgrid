extends Node

# Manages high-level game state: current screen and pause.
# Emits changes through SignalBus so UI and scenes react.

# ─── State ─────────────────────────────────────────
var current_screen: SignalBus.Screen = SignalBus.Screen.MAIN_MENU
var is_paused: bool = false

# Inimigo do próximo combate. Se != null, o ArenaManager o usa e reseta.
# Ponto único para a Fase 4 (hub) escolher encontros (ex: Boss).
var next_enemy_scene: PackedScene = null

# ─── Estado de Run (volátil; HP não vai para o save) ──
var run_active: bool = false
var caipora_max_hp: int = Constants.CAIPORA_MAX_HEALTH
var caipora_current_hp: int = Constants.CAIPORA_MAX_HEALTH

## Inicia uma nova run: HP cheio, com bônus de meta aplicado.
func start_run() -> void:
	run_active = true
	caipora_max_hp = Constants.CAIPORA_MAX_HEALTH + MetaProgression.get_bonus_max_hp()
	caipora_current_hp = caipora_max_hp

## Recupera HP cheio (chamado ao entrar no Hub). Recalcula o max com o bônus atual.
func heal_to_full() -> void:
	caipora_max_hp = Constants.CAIPORA_MAX_HEALTH + MetaProgression.get_bonus_max_hp()
	caipora_current_hp = caipora_max_hp

## Encerra a run, registra estatísticas e persiste.
func end_run(won: bool) -> void:
	run_active = false
	MetaProgression.total_runs += 1
	if won:
		MetaProgression.total_wins += 1
	MetaProgression.save_progress()

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
